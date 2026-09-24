import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/ws/command_dispatcher.dart';
import 'package:saaradhigo_driver/core/ws/ws_client.dart';

import 'helpers/fakes.dart';

/// `send()` succeeding is not a command succeeding.
///
/// A resolved pilot blocker turned on exactly that: the driver's socket had been
/// closed, `send()` succeeded anyway, and the app reported a finished ride whose
/// trip was still `in_progress`. These tests pin the client half of the fix — the
/// app now waits for the server's `command_ack`, and retries the SAME command_id
/// when the acknowledgement does not arrive.
void main() {
  late FakeWsChannel channel;

  WsClient buildClient() {
    return WsClient(
      path: () async => '/ride/trip/7/?token=t',
      tokenProvider: () async => 't',
      // Long enough that the keepalive timer never fires inside a test.
      pingInterval: const Duration(minutes: 5),
      connector: (uri) {
        channel = FakeWsChannel();
        return channel;
      },
    );
  }

  /// The command_id the app put on the wire for frame [index].
  String sentCommandId(int index) =>
      (jsonDecode(channel.sent[index]) as Map<String, dynamic>)['command_id']
          as String;

  Map<String, dynamic> sentFrame(int index) =>
      jsonDecode(channel.sent[index]) as Map<String, dynamic>;

  test('a committed ack resolves as success and reports the durable status',
      () async {
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();
    final dispatcher = CommandDispatcher(socket: client);

    final pending = dispatcher.send('complete');
    await Future<void>.delayed(Duration.zero);

    final id = sentCommandId(0);
    channel.emit({
      'type': 'command_ack',
      'command': 'complete',
      'command_id': id,
      'status': 'committed',
      'trip_status': 'completed',
    });

    final result = await pending;
    expect(result.isSuccess, isTrue);
    expect(result.outcome, CommandOutcome.committed);
    expect(result.tripStatus, 'completed');
    expect(result.attempts, 1);
    expect(result.wasAlreadyDone, isFalse);
  });

  test('already_done is success, not failure', () async {
    // The retry case. The server is telling us a previous attempt of this exact
    // command already committed; presenting that as an error is what would show a
    // driver a failure on a ride that had finished.
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();
    final dispatcher = CommandDispatcher(socket: client);

    final pending = dispatcher.send('complete');
    await Future<void>.delayed(Duration.zero);

    channel.emit({
      'type': 'command_ack',
      'command': 'complete',
      'command_id': sentCommandId(0),
      'status': 'already_done',
      'trip_status': 'completed',
      'reason': 'already_in_target_state',
    });

    final result = await pending;
    expect(result.isSuccess, isTrue);
    expect(result.wasAlreadyDone, isTrue);
    expect(result.tripStatus, 'completed');
  });

  test('a lost ack is retried with the SAME command_id', () async {
    // The whole point of a client-generated id: the server must be able to see
    // that attempt 2 is the same logical command as attempt 1, not new work.
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();
    final dispatcher = CommandDispatcher(
      socket: client,
      ackTimeout: const Duration(milliseconds: 300),
      maxAttempts: 3,
    );

    final pending = dispatcher.send('complete');

    // Wait for the retry to actually go out rather than guessing at the backoff.
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (channel.sent.length < 2 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(channel.sent.length, greaterThanOrEqualTo(2),
        reason: 'a timed-out command must be retried');
    final first = sentCommandId(0);
    final second = sentCommandId(1);
    expect(second, first,
        reason: 'a retry must reuse the command_id so the server can dedupe it');

    channel.emit({
      'type': 'command_ack',
      'command': 'complete',
      'command_id': first,
      'status': 'already_done',
      'trip_status': 'completed',
    });

    final result = await pending;
    expect(result.isSuccess, isTrue);
    expect(result.attempts, greaterThan(1));
    expect(result.commandId, first);
  });

  test('a rejection is terminal and is never retried', () async {
    // Retrying an authorisation failure or an invalid transition would loop
    // forever against an answer that will not change.
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();
    final dispatcher = CommandDispatcher(
      socket: client,
      ackTimeout: const Duration(milliseconds: 60),
      maxAttempts: 4,
    );

    final pending = dispatcher.send('start', extra: {'otp': '000000'});
    await Future<void>.delayed(Duration.zero);

    channel.emit({
      'type': 'command_ack',
      'command': 'start',
      'command_id': sentCommandId(0),
      'status': 'rejected',
      'reason': 'invalid_otp',
      'trip_status': 'reached',
      'detail': 'Invalid OTP provided',
    });

    final result = await pending;
    expect(result.outcome, CommandOutcome.rejected);
    expect(result.reason, 'invalid_otp');
    expect(result.tripStatus, 'reached');
    expect(result.attempts, 1);

    // And nothing further went out.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(channel.sent.length, 1,
        reason: 'a rejected command must not be retried');
  });

  test('retries are bounded and end in unknown, never in a false success',
      () async {
    // `unknown` exists so the caller reconciles against durable state instead of
    // guessing. Reporting an unacknowledged command as either success or failure
    // is what created the original defect.
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();
    final dispatcher = CommandDispatcher(
      socket: client,
      ackTimeout: const Duration(milliseconds: 40),
      maxAttempts: 3,
    );

    final result = await dispatcher.send('complete');

    expect(result.outcome, CommandOutcome.unknown);
    expect(result.isSuccess, isFalse);
    expect(result.reason, 'ack_timeout');
    expect(result.attempts, 3);
    expect(channel.sent.length, 3,
        reason: 'exactly maxAttempts sends, no unbounded loop');
  });

  test('an ack for a different command is ignored', () async {
    // Correlation, not "the next frame that looks like an ack".
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();
    final dispatcher = CommandDispatcher(
      socket: client,
      ackTimeout: const Duration(milliseconds: 200),
      maxAttempts: 1,
    );

    final pending = dispatcher.send('complete');
    await Future<void>.delayed(Duration.zero);

    channel.emit({
      'type': 'command_ack',
      'command': 'reached',
      'command_id': 'somebody-elses-command',
      'status': 'committed',
      'trip_status': 'reached',
    });

    final result = await pending;
    expect(result.outcome, CommandOutcome.unknown,
        reason: 'an ack whose command_id does not match must not resolve us');
  });

  test('the command frame carries the action, the id and any extras', () async {
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();
    final dispatcher = CommandDispatcher(
      socket: client,
      ackTimeout: const Duration(milliseconds: 40),
      maxAttempts: 1,
    );

    await dispatcher.send('start', extra: {'otp': '123456'});

    final frame = sentFrame(0);
    expect(frame['action'], 'start');
    expect(frame['otp'], '123456');
    expect(frame['command_id'], isA<String>());
    expect((frame['command_id'] as String).isNotEmpty, isTrue);
  });

  test('a supplied command_id is reused, so a resumed command is recognised',
      () async {
    // Lets a command survive an app restart: persist the id, resume with it, and
    // the server answers `already_done` if the original attempt landed.
    final client = buildClient();
    addTearDown(client.dispose);
    await client.connect();
    final dispatcher = CommandDispatcher(
      socket: client,
      ackTimeout: const Duration(milliseconds: 40),
      maxAttempts: 1,
    );

    await dispatcher.send('complete', commandId: 'resumed-42');

    expect(sentFrame(0)['command_id'], 'resumed-42');
  });

  test('nothing is sent while the socket is down', () async {
    // Shouting into a closed socket is the failure this class exists to prevent.
    final client = buildClient();
    addTearDown(client.dispose);
    // Deliberately not connected.
    final dispatcher = CommandDispatcher(
      socket: client,
      ackTimeout: const Duration(milliseconds: 40),
      maxAttempts: 2,
      reconnectGrace: const Duration(milliseconds: 60),
    );

    final result = await dispatcher.send('complete');

    expect(result.outcome, CommandOutcome.unknown);
    expect(result.reason, 'not_connected');
  });

  group('graceful degradation against a server without ack support', () {
    // A version skew must not leave every lifecycle command hanging. That would
    // be a worse failure than the one the ack protocol fixes, so the old
    // uncorrelated signals still count as answers.

    test('a trip_status_update broadcast resolves the command', () async {
      final client = buildClient();
      addTearDown(client.dispose);
      await client.connect();
      final dispatcher = CommandDispatcher(
        socket: client,
        ackTimeout: const Duration(milliseconds: 400),
        maxAttempts: 1,
      );

      final pending = dispatcher.send('complete');
      await Future<void>.delayed(Duration.zero);

      channel.emit({
        'type': 'trip_status_update',
        'trip_id': 101,
        'status': 'complete',
        'message': 'Trip completed',
      });

      final result = await pending;
      expect(result.isSuccess, isTrue);
      expect(result.viaBroadcast, isTrue,
          reason: 'so a version skew is visible in telemetry');
      expect(result.tripStatus, 'complete');
    });

    test('a broadcast for a DIFFERENT action does not resolve the command',
        () async {
      final client = buildClient();
      addTearDown(client.dispose);
      await client.connect();
      final dispatcher = CommandDispatcher(
        socket: client,
        ackTimeout: const Duration(milliseconds: 200),
        maxAttempts: 1,
      );

      final pending = dispatcher.send('complete');
      await Future<void>.delayed(Duration.zero);

      channel.emit({
        'type': 'trip_status_update',
        'trip_id': 101,
        'status': 'reached',
      });

      final result = await pending;
      expect(result.outcome, CommandOutcome.unknown,
          reason: 'another trip event must not be mistaken for our answer');
    });

    test('a legacy error frame resolves as rejected', () async {
      final client = buildClient();
      addTearDown(client.dispose);
      await client.connect();
      final dispatcher = CommandDispatcher(
        socket: client,
        ackTimeout: const Duration(milliseconds: 400),
        maxAttempts: 3,
      );

      final pending = dispatcher.send('start', extra: {'otp': '000000'});
      await Future<void>.delayed(Duration.zero);

      channel.emit({'type': 'error', 'message': 'Invalid OTP provided'});

      final result = await pending;
      expect(result.outcome, CommandOutcome.rejected);
      expect(result.detail, contains('OTP'));
      expect(channel.sent.length, 1, reason: 'a rejection is not retried');
    });

    test('a correlated ack is preferred over a broadcast', () async {
      final client = buildClient();
      addTearDown(client.dispose);
      await client.connect();
      final dispatcher = CommandDispatcher(
        socket: client,
        ackTimeout: const Duration(milliseconds: 400),
        maxAttempts: 1,
      );

      final pending = dispatcher.send('complete');
      await Future<void>.delayed(Duration.zero);

      channel.emit({
        'type': 'command_ack',
        'command': 'complete',
        'command_id': sentCommandId(0),
        'status': 'committed',
        'trip_status': 'completed',
      });

      final result = await pending;
      expect(result.viaBroadcast, isFalse);
      expect(result.tripStatus, 'completed');
    });
  });
}
