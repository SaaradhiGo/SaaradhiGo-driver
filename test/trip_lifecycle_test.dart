import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/providers.dart';
import 'package:saaradhigo_driver/features/trip/domain/trip.dart';
import 'package:saaradhigo_driver/features/trip/presentation/trip_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saaradhigo_driver/core/storage/local_store.dart';

import 'helpers/fakes.dart';

/// End-to-end exercise of the trip state machine over a faked WebSocket.
///
/// This is the flow that carries the money and the rider, so it is driven
/// frame by frame against the exact payloads `TripStatusConsumer` emits
/// rather than mocked at the controller boundary.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTripRepository trips;
  late ProviderContainer container;

  /// One channel per connect attempt, mirroring what a real reconnect does.
  final channels = <FakeWsChannel>[];
  FakeWsChannel channel() => channels.last;

  Map<String, dynamic> lastSent() =>
      jsonDecode(channel().sent.last) as Map<String, dynamic>;

  List<Map<String, dynamic>> allSent() => channel().sent
      .map((raw) => jsonDecode(raw) as Map<String, dynamic>)
      .toList();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final localStore = await LocalStore.create();
    channels
      ..clear()
      ..add(FakeWsChannel());
    trips = FakeTripRepository(active: buildTrip());

    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        tokenStoreProvider.overrideWithValue(FakeTokenStore(access: 'tok')),
        tripRepositoryProvider.overrideWithValue(trips),
        wsConnectorProvider.overrideWithValue((uri) {
          if (channels.last.closed) channels.add(FakeWsChannel());
          return channels.last;
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  group('accept', () {
    test('winning the race adopts the trip and opens its socket', () async {
      final controller = container.read(tripControllerProvider.notifier);

      final accepting = controller.acceptOffer(101);
      await settle();

      expect(lastSent()['action'], 'accept');

      // The server broadcasts the accepted status to the trip group.
      channel().emit({
        'type': 'trip_status_update',
        'trip_id': 101,
        'status': 'accept',
      });

      expect(await accepting, isTrue);
      final state = container.read(tripControllerProvider);
      expect(state.hasTrip, isTrue);
      expect(state.trip!.id, 101);
    });

    test('losing the race to trip_taken does not adopt the trip', () async {
      final controller = container.read(tripControllerProvider.notifier);

      final accepting = controller.acceptOffer(101);
      await settle();

      // Another driver got there first.
      channel().emit({'type': 'trip_taken', 'trip_id': 101});

      expect(await accepting, isFalse);
      expect(container.read(tripControllerProvider).hasTrip, isFalse,
          reason: 'a lost race must leave the driver free for the next offer');
    });

    test('a server error frame during accept fails cleanly', () async {
      final controller = container.read(tripControllerProvider.notifier);

      final accepting = controller.acceptOffer(101);
      await settle();

      channel().emit({
        'type': 'error',
        'message': 'You have reached the 12-hour daily limit',
      });

      expect(await accepting, isFalse);
      expect(container.read(tripControllerProvider).hasTrip, isFalse);
    });
  });

  group('lifecycle', () {
    Future<TripController> acceptedController() async {
      final controller = container.read(tripControllerProvider.notifier);
      final accepting = controller.acceptOffer(101);
      await settle();
      channel().emit({
        'type': 'trip_status_update',
        'trip_id': 101,
        'status': 'accept',
      });
      await accepting;
      return controller;
    }

    // A lifecycle command is now request/response: the controller waits for the
    // server's answer instead of firing and hoping. So the reply has to be emitted
    // while the command is in flight -- awaiting the command first would deadlock,
    // which is exactly what a driver app hanging on `isBusy` looked like before.
    //
    // These tests deliberately answer with the OLD `trip_status_update` broadcast
    // and no `command_ack` at all. That is the compatibility proof: the app still
    // works against a server that predates the ack protocol.
    test('arrived → start with OTP → complete follows the server', () async {
      final controller = await acceptedController();

      final arriving = controller.markArrived();
      await settle();
      expect(lastSent()['action'], 'reached');
      channel().emit({
        'type': 'trip_status_update',
        'trip_id': 101,
        'status': 'reached',
      });
      await arriving;
      await settle();
      expect(container.read(tripControllerProvider).trip!.status,
          TripStatus.reached);

      final starting = controller.startTrip('123456');
      await settle();
      expect(lastSent()['action'], 'start');
      expect(lastSent()['otp'], '123456',
          reason: 'the rider OTP is what proves the right passenger boarded');
      channel().emit({
        'type': 'trip_status_update',
        'trip_id': 101,
        'status': 'start',
      });
      await starting;
      await settle();
      final started = container.read(tripControllerProvider).trip!;
      expect(started.status, TripStatus.inProgress);
      expect(started.otpVerified, isTrue);

      final completing = controller.completeTrip();
      await settle();
      expect(lastSent()['action'], 'complete');
      channel().emit({
        'type': 'trip_status_update',
        'trip_id': 101,
        'status': 'complete',
      });
      await completing;
      await settle();
      final finished = container.read(tripControllerProvider);
      expect(finished.trip!.status, TripStatus.completed);
      expect(finished.justCompleted, isTrue,
          reason: 'the UI needs a one-shot signal to show the payment screen');
    });

    test('a wrong OTP surfaces inline, not as a failure banner', () async {
      final controller = await acceptedController();

      final starting = controller.startTrip('000000');
      await settle();
      channel().emit({
        'type': 'error',
        'message': 'Invalid OTP provided',
      });
      await starting;
      await settle();

      final state = container.read(tripControllerProvider);
      expect(state.otpError, contains('Invalid OTP'));
      expect(state.error, isNull,
          reason: 'a mistyped OTP is routine, not an app error');
      expect(state.trip!.status, TripStatus.accepted,
          reason: 'a rejected start must not advance the trip');
    });

    test('confirm_cash is sent and the payment status flips', () async {
      final controller = await acceptedController();

      final confirming = controller.confirmCash();
      await settle();
      expect(lastSent()['action'], 'confirm_cash');
      channel().emit({'type': 'cash_payment_confirmed', 'trip_id': 101});
      await confirming;
      await settle();

      expect(container.read(tripControllerProvider).trip!.isPaid, isTrue);
    });

    test('actions are refused while the socket is down', () async {
      final controller = container.read(tripControllerProvider.notifier);

      // No socket has been opened at all.
      await controller.markArrived();

      expect(container.read(tripControllerProvider).error, isNotNull);
      expect(channel().sent, isEmpty,
          reason: 'nothing may be sent into a dead socket');
    });

    test('cancelling goes over REST and clears the trip', () async {
      final controller = await acceptedController();

      final ok = await controller.cancelTrip(reason: 'no_show');

      expect(ok, isTrue);
      expect(trips.cancelCount, 1);
      expect(container.read(tripControllerProvider).hasTrip, isFalse);
      // Cancel is deliberately NOT a socket action: the REST endpoint is what
      // applies the penalty ledger and the cancellation cooldown.
      expect(
        allSent().any((frame) => frame['action'] == 'cancel'),
        isFalse,
      );
    });
  });

  group('crash recovery', () {
    test('restores from the local snapshot then reconciles with the server',
        () async {
      final controller = container.read(tripControllerProvider.notifier);

      await controller.restore();
      await settle();

      final state = container.read(tripControllerProvider);
      expect(state.hasTrip, isTrue);
      expect(state.trip!.id, 101,
          reason: 'a driver whose app died mid-ride must land back on it');
    });

    test('clears a stale snapshot when the server says there is no trip',
        () async {
      trips.active = null;
      final controller = container.read(tripControllerProvider.notifier);

      await controller.restore();
      await settle();

      expect(container.read(tripControllerProvider).hasTrip, isFalse,
          reason: 'the server is authoritative over the local cache');
    });
  });
}
