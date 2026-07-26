import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/ws/ws_client.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeWsChannel channel;
  var connectCount = 0;
  final connectedUris = <Uri>[];

  WsClient buildClient({String token = 'token-1'}) {
    connectCount = 0;
    connectedUris.clear();
    return WsClient(
      path: () async => '/driver/location/?token=$token&lat=17.4&lng=78.4',
      tokenProvider: () async => token,
      // Long enough that the ping timer never fires inside a test.
      pingInterval: const Duration(minutes: 5),
      connector: (uri) {
        connectCount++;
        connectedUris.add(uri);
        channel = FakeWsChannel();
        return channel;
      },
    );
  }

  test('connects and reports connected status', () async {
    final client = buildClient();
    addTearDown(client.dispose);

    await client.connect();

    expect(client.isConnected, isTrue);
    expect(connectCount, 1);
    expect(connectedUris.single.toString(), contains('token=token-1'));
  });

  test('decodes server frames onto the events stream', () async {
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();

    final received = <Map<String, dynamic>>[];
    final sub = client.events.listen(received.add);

    channel.emit({'type': 'location_updated', 'lat': 17.4, 'lng': 78.4});
    channel.emit({
      'type': 'ride_request',
      'trip_id': 101,
      'estimated_fare': '245.50',
    });
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(2));
    expect(received.first['type'], 'location_updated');
    expect(received.last['trip_id'], 101);

    await sub.cancel();
  });

  test('drops a malformed frame without killing the stream', () async {
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();

    final received = <Map<String, dynamic>>[];
    final sub = client.events.listen(received.add);

    // A single bad frame must not take dispatch down.
    channel.emitRaw('this is not json');
    channel.emit({'type': 'ride_request', 'trip_id': 5});
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single['trip_id'], 5);

    await sub.cancel();
  });

  test('sends json frames to the server', () async {
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();

    client.send({'lat': 17.1, 'lng': 78.2});

    final decoded = jsonDecode(channel.sent.single) as Map;
    expect(decoded['lat'], 17.1);
    expect(decoded['lng'], 78.2);
  });

  test('reconnects automatically after the socket drops', () async {
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();
    expect(connectCount, 1);

    final statuses = <WsStatus>[];
    final sub = client.status.listen(statuses.add);

    channel.kill();
    // First backoff is ~1s ±15% jitter.
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    expect(statuses, contains(WsStatus.reconnecting));
    expect(connectCount, greaterThanOrEqualTo(2),
        reason: 'a dropped dispatch socket must re-establish itself');

    await sub.cancel();
  });

  test('close() stops the socket without reconnecting', () async {
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();

    await client.close();
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    expect(client.currentStatus, WsStatus.closed);
    expect(connectCount, 1, reason: 'an intentional close must stay closed');
  });

  test('refuses to connect without a token', () async {
    final client = WsClient(
      path: () async => '/driver/location/',
      tokenProvider: () async => null,
      connector: (uri) => FakeWsChannel(),
    );
    addTearDown(client.dispose);

    await client.connect();

    expect(client.currentStatus, WsStatus.closed);
    expect(client.isConnected, isFalse);
  });
}
