// Regression for the trip #79 failure on QA.
//
// WHAT HAPPENED
// The driver accepted a ride offer that the backend had ALREADY cancelled
// (`cancellation_reason = no_driver_accepted` — dispatch had run its waves
// and given up). The accept was refused, no `trip_status_update` ever
// arrived, and the app stayed on "Preparing ride…" indefinitely. Because it
// held the trip screen, it displayed no further offers: the driver was
// invisible to dispatch while still showing as online. The next booking
// (trip #80) produced no offer at all, and only a force-stop recovered it.
//
// The fix bounds the wait and then asks the BACKEND what is true, because the
// app's own state is the thing in doubt.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';
import 'package:saaradhigo_driver/core/storage/local_storage_service.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/dashboard/data/data_sources/driver_location_consumer.dart';
import 'package:saaradhigo_driver/features/trip/data/data_sources/trip_status_consumer.dart';
import 'package:saaradhigo_driver/features/trip/domain/repositories/trip_repository.dart';
import 'package:saaradhigo_driver/features/trip/presentation/providers/trip_providers.dart';

class _FakeConsumer implements TripStatusConsumer {
  _FakeConsumer(this.tripId);

  @override
  final int tripId;

  final _events = StreamController<TripStatusEvent>.broadcast();
  final _conn = StreamController<WebSocketState>.broadcast();

  bool connected = false;
  bool disposed = false;
  final List<String> sentActions = [];

  @override
  Stream<TripStatusEvent> get events => _events.stream;

  @override
  Stream<WebSocketState> get connectionState => _conn.stream;

  @override
  void connect() {
    connected = true;
    _conn.add(WebSocketState.connected);
    // The real consumer emits this once the channel is ready; the notifier
    // sends the queued `accept` on it.
    _events.add(TripConnectionEstablished(tripId: tripId));
  }

  @override
  void disconnect() {
    connected = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _events.close();
    await _conn.close();
  }

  @override
  void sendAction(String action, {String? otp, String? reason}) {
    sentActions.add(action);
  }

  @override
  void updateNetworkStatus(bool isOnline) {}

  void emit(TripStatusEvent event) => _events.add(event);
}

/// Stands in for `/ride/active/`.
class _FakeTripRepository implements TripRepository {
  _FakeTripRepository({this.active, this.throws = false});

  TripModel? active;
  bool throws;
  int calls = 0;

  @override
  Future<TripModel?> getActiveTrip() async {
    calls += 1;
    if (throws) throw Exception('network down');
    return active;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _offer = DriverLocationRideRequest(<String, dynamic>{'trip_id': 79});

ProviderContainer _container(
  _FakeTripRepository repo,
  void Function(_FakeConsumer) capture,
) {
  return ProviderContainer(
    overrides: [
      tripRepositoryProvider.overrideWithValue(repo),
      tripStatusConsumerFactoryProvider.overrideWithValue((id) {
        final c = _FakeConsumer(id);
        capture(c);
        return c;
      }),
    ],
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  tearDown(() async {
    await LocalStorageService.clearAll();
  });

  group('stale offer recovery (trip #79)', () {
    test(
      'an accept the backend never confirms releases the driver back online',
      () {
        fakeAsync((async) {
          late _FakeConsumer consumer;
          // The backend has no active trip for us: the offer was cancelled
          // before our accept landed. This is trip #79 exactly.
          final repo = _FakeTripRepository(active: null);
          final container = _container(repo, (c) => consumer = c);
          addTearDown(container.dispose);

          final notifier = container.read(tripSessionNotifierProvider.notifier);
          unawaited(notifier.acceptFromRequest(_offer));
          async.flushMicrotasks();

          // Mid-flight: this is the "Preparing ride…" screen.
          expect(consumer.sentActions, contains('accept'));
          expect(container.read(tripSessionNotifierProvider).trip, isNotNull);

          // Before the bound, we are still waiting — we do not give up early.
          async.elapse(const Duration(seconds: 10));
          expect(container.read(tripSessionNotifierProvider).offerLost, isFalse);

          // Past the bound: reconcile and release.
          async.elapse(const Duration(seconds: 10));
          async.flushMicrotasks();

          final state = container.read(tripSessionNotifierProvider);
          expect(repo.calls, 1, reason: 'must ask the backend, not guess');
          expect(state.offerLost, isTrue);
          expect(state.trip, isNull, reason: 'no stale ride screen may remain');
          expect(state.status, isNull);
          expect(state.errorMessage, isNotNull);
          expect(
            LocalStorageService.getActiveTripId(),
            isNull,
            reason: 'a released ride must not be resumed on next launch',
          );
        });
      },
    );

    test('a legitimately assigned trip is adopted, not thrown away', () {
      fakeAsync((async) {
        late _FakeConsumer consumer;
        // The accept DID work; only the status update was lost.
        final repo = _FakeTripRepository(
          active: const TripModel(id: 79, status: TripStatus.accepted),
        );
        final container = _container(repo, (c) => consumer = c);
        addTearDown(container.dispose);

        final notifier = container.read(tripSessionNotifierProvider.notifier);
        unawaited(notifier.acceptFromRequest(_offer));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        final state = container.read(tripSessionNotifierProvider);
        expect(state.offerLost, isFalse);
        expect(state.trip?.id, 79);
        expect(state.status, TripStatus.accepted);
        expect(consumer.tripId, 79);
      });
    });

    test('a confirmed acceptance is never torn down by the watchdog', () {
      fakeAsync((async) {
        late _FakeConsumer consumer;
        final repo = _FakeTripRepository(active: null);
        final container = _container(repo, (c) => consumer = c);
        addTearDown(container.dispose);

        final notifier = container.read(tripSessionNotifierProvider.notifier);
        unawaited(notifier.acceptFromRequest(_offer));
        async.flushMicrotasks();

        // The backend confirms normally.
        consumer.emit(const TripStatusChanged(
          status: TripStatus.accepted,
          raw: <String, dynamic>{'status': 'accept'},
        ));
        async.flushMicrotasks();

        // Well past the bound.
        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();

        final state = container.read(tripSessionNotifierProvider);
        expect(state.offerLost, isFalse,
            reason: 'a real ride must survive the timeout window');
        expect(state.status, TripStatus.accepted);
        expect(repo.calls, 0, reason: 'nothing to reconcile');
      });
    });

    test('a failed reconcile still releases rather than stranding', () {
      fakeAsync((async) {
        late _FakeConsumer consumer;
        final repo = _FakeTripRepository(throws: true);
        final container = _container(repo, (c) => consumer = c);
        addTearDown(container.dispose);

        final notifier = container.read(tripSessionNotifierProvider.notifier);
        unawaited(notifier.acceptFromRequest(_offer));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        final state = container.read(tripSessionNotifierProvider);
        expect(state.offerLost, isTrue);
        expect(state.trip, isNull);
        expect(consumer.disposed, isTrue,
            reason: 'the trip socket must be let go');
      });
    });

    test('duplicate acceptance of the same offer is ignored', () {
      fakeAsync((async) {
        final repo = _FakeTripRepository(
          active: const TripModel(id: 79, status: TripStatus.accepted),
        );
        final consumers = <_FakeConsumer>[];
        final container = _container(repo, consumers.add);
        addTearDown(container.dispose);

        final notifier = container.read(tripSessionNotifierProvider.notifier);
        unawaited(notifier.acceptFromRequest(_offer));
        async.flushMicrotasks();
        unawaited(notifier.acceptFromRequest(_offer));
        async.flushMicrotasks();

        expect(consumers.length, 1,
            reason: 'a second accept must not open a second trip channel');
      });
    });
  });
}
