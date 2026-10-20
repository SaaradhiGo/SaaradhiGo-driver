import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/status.dart' as status;

/// THE DEFECT, FOUND BY ACCEPTING TRIP #94 ON QA
///
/// The driver accepted, the command acked, and then:
///
///   Unhandled Exception: Invalid argument(s): Invalid argument: 1001,
///   close code must be 1000 or in the range 3000-4999
///   <= Error 404 /api/v1/ride/active/  {code: NO_ACTIVE_TRIP}
///
/// `WebSocketService` closed its channel with `status.goingAway`, which is
/// 1001. dart:io's `WebSocket.close()` refuses that code outright, so every
/// teardown threw. The throw aborted the flow that adopts the accepted trip,
/// the driver was left with no active trip, and the ride expired with a
/// driver sitting right there.
///
/// 1001 is also wrong semantically: it means "the server is going away". A
/// client hanging up is 1000.
void main() {
  /// dart:io's own rule -- the one that actually threw.
  bool acceptedByDartIo(int code) =>
      code == 1000 || (code >= 3000 && code <= 4999);

  group('WebSocket close codes', () {
    test('goingAway (1001) is refused by dart:io — this was the bug', () {
      expect(status.goingAway, 1001);
      expect(
        acceptedByDartIo(status.goingAway),
        isFalse,
        reason: 'closing with 1001 throws, which is what broke trip #94',
      );
    });

    test('normalClosure (1000) is accepted — this is the fix', () {
      expect(status.normalClosure, 1000);
      expect(acceptedByDartIo(status.normalClosure), isTrue);
    });

    test('no teardown in the service closes with a refused code', () {
      // A source check on purpose: the throw happens inside a real socket
      // sink that a fake channel does not reproduce, so what is worth
      // pinning is that no forbidden close code is reachable at all.
      final source =
          File('lib/core/network/websocket_service.dart').readAsStringSync();

      expect(
        source.contains('close(status.goingAway)'),
        isFalse,
        reason: 'a teardown still closes with 1001',
      );
      expect(
        source.contains('close(status.normalClosure)'),
        isTrue,
        reason: 'teardowns should close with 1000',
      );
    });
  });
}
