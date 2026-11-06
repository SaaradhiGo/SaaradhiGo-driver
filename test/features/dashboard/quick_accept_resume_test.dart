// Regression for the quick-accept drop seen on QA on 2026-11-06.
//
// WHAT HAPPENED
// An offer arrived while the driver app was in the background. The driver
// brought the app forward and tapped Accept within about two seconds. The
// offer closed, no accept reached the server, and the ride was lost.
//
// WHY
// Resume asks the server for the driver's active trip (`/ride/active/`).
// Its answer -- "none", true when it was asked -- landed after the Accept tap
// had started a trip session, and Home cleared that session as stale, tearing
// the trip socket down before the queued accept could be sent. Resume also
// re-reads the location permission, and a momentary "denied" took an online
// driver offline at once.
//
// The test replays that sequence: driver online, offer pending, resume with
// the active-trip request in flight and a location blip, Accept 500 ms after
// resume, then the stale answer.

import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saaradhigo_driver/core/location/location_notifier.dart';
import 'package:saaradhigo_driver/core/location/location_providers.dart';
import 'package:saaradhigo_driver/core/network/connectivity_provider.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';
import 'package:saaradhigo_driver/core/notifications/ride_offer_coordinator.dart';
import 'package:saaradhigo_driver/core/storage/local_storage_service.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/dashboard/data/data_sources/driver_location_consumer.dart';
import 'package:saaradhigo_driver/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_providers.dart';
import 'package:saaradhigo_driver/features/trip/data/data_sources/trip_status_consumer.dart';
import 'package:saaradhigo_driver/features/trip/domain/repositories/trip_repository.dart';
import 'package:saaradhigo_driver/features/trip/presentation/providers/trip_providers.dart';

import '../../core/network/test_websocket_channel.dart';
import '../../core/notifications/fake_push_transport.dart';

const _tripId = 143;

LocationState _tracking() => LocationState.tracking(
  position: const LatLng(17.444, 78.381),
  timestamp: DateTime.utc(2026, 11, 6, 11),
  hasBackgroundAccess: true,
);

/// Location whose state the test drives, as resume's permission re-read does.
class _Location extends LocationNotifier {
  @override
  LocationState build() => _tracking();

  void emit(LocationState next) => state = next;

  @override
  Future<void> setForegroundNotification({
    required bool enabled,
    String? title,
    String? subtitle,
  }) async {}

  @override
  Future<void> updateNotificationText({
    String? title,
    String? subtitle,
  }) async {}
}

/// The trip socket: ready only when the test says so, like a real handshake.
class _TripSocket implements TripStatusConsumer {
  _TripSocket(this.tripId);

  @override
  final int tripId;

  final _events = StreamController<TripStatusEvent>.broadcast();
  final _conn = StreamController<WebSocketState>.broadcast();
  final List<Map<String, String?>> sent = [];
  bool disposed = false;

  @override
  Stream<TripStatusEvent> get events => _events.stream;

  @override
  Stream<WebSocketState> get connectionState => _conn.stream;

  @override
  void connect() => _conn.add(WebSocketState.connecting);

  void ready() => _events.add(TripConnectionEstablished(tripId: tripId));

  @override
  void disconnect() {}

  @override
  Future<void> dispose() async {
    disposed = true;
    await _events.close();
    await _conn.close();
  }

  @override
  void sendAction(
    String action, {
    String? otp,
    String? reason,
    String? commandId,
  }) {
    sent.add({'action': action, 'command_id': commandId});
  }

  @override
  void updateNetworkStatus(bool isOnline) {}

  void emit(TripStatusEvent event) => _events.add(event);
}

/// `/ride/active/`, answered when the test completes [pending].
class _ActiveTrip implements TripRepository {
  final List<Completer<TripModel?>> pending = [];

  @override
  Future<TripModel?> getActiveTrip() {
    final c = Completer<TripModel?>();
    pending.add(c);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  test('Accept within 500 ms of resume: one accept is sent and the driver '
      'stays online', () {
    fakeAsync((async) {
      final location = _Location();
      final repo = _ActiveTrip();
      final sockets = <_TripSocket>[];
      final dispatch = TestWebSocketChannel();
      final container = ProviderContainer(
        overrides: [
          isOnlineNetworkProvider.overrideWithValue(true),
          driverProfileNotifierProvider.overrideWithBuild(
            (ref, notifier) => ProfileState.loaded(
              const DriverProfileModel(
                id: 18,
                status: DriverStatus.offline,
                approved: true,
                activeVehicle: 7,
              ),
            ),
          ),
          locationNotifierProvider.overrideWith(() => location),
          driverLocationConsumerFactoryProvider.overrideWithValue(
            () => DriverLocationConsumer(
              tokenReader: () async => 'jwt',
              positionReader: () => const LatLng(17.444, 78.381),
              wsBaseUrlReader: () => 'wss://api.example/',
              serviceFactory: (urlBuilder) => WebSocketService(
                urlBuilder: urlBuilder,
                channelFactory: (_) => dispatch,
              ),
            ),
          ),
          tripRepositoryProvider.overrideWithValue(repo),
          tripStatusConsumerFactoryProvider.overrideWithValue((id) {
            final s = _TripSocket(id);
            sockets.add(s);
            return s;
          }),
        ],
      );
      addTearDown(container.dispose);
      final coordinator = RideOfferCoordinator(
        transport: FakePushTransport(),
        hasActiveTrip: () =>
            container.read(tripSessionNotifierProvider).isActive,
      );
      addTearDown(coordinator.dispose);

      // 1. The driver is online.
      final availability = container.read(
        availabilityNotifierProvider.notifier,
      );
      availability.goOnline();
      async.flushMicrotasks();
      dispatch.incoming.add(
        '{"type":"connection_established","message":"Driver 18 connected"}',
      );
      async.flushMicrotasks();
      expect(
        container.read(availabilityNotifierProvider),
        isA<AvailabilityStateOnline>(),
      );

      // 2. An offer arrives while the app is in the background.
      final payload = <String, dynamic>{
        'type': 'ride_request',
        'trip_id': _tripId,
      };
      dispatch.incoming.add(jsonEncode(payload));
      async.flushMicrotasks();
      expect(
        coordinator.onSocketOffer(_tripId, payload),
        OfferDecision.presented,
      );
      final offer = coordinator.pendingOffer!;

      // 3. Resume: Home asks for the active trip and re-reads the location
      // permission, which reports a loss for a moment.
      final session = container.read(tripSessionNotifierProvider.notifier);
      TripModel? rejoin;
      var answered = false;
      session.reconcileWithServer().then((t) {
        rejoin = t;
        answered = true;
      });
      location.emit(const LocationState.permissionDenied(permanent: false));
      async.flushMicrotasks();

      // 4. Accept, 500 ms after resume, while that request is in flight.
      async.elapse(const Duration(milliseconds: 500));
      location.emit(_tracking());
      coordinator.markSettled(offer.tripId);
      session.acceptFromRequest(DriverLocationRideRequest(offer.payload));
      async.flushMicrotasks();

      // 5. The answer to the resume request arrives: "no active trip", true
      // when it was asked. It must not clear the accept.
      repo.pending.single.complete(null);
      async.flushMicrotasks();
      expect(answered, isTrue);
      expect(rejoin, isNull);
      expect(sockets.single.disposed, isFalse);
      expect(container.read(tripSessionNotifierProvider).trip?.id, _tripId);

      // 6. The trip socket comes up; the queued accept goes out.
      sockets.single.ready();
      async.flushMicrotasks();
      // A second tap on the same offer changes nothing.
      session.acceptFromRequest(DriverLocationRideRequest(offer.payload));
      sockets.single.ready();
      async.flushMicrotasks();

      expect(sockets, hasLength(1));
      expect(sockets.single.sent, hasLength(1));
      expect(sockets.single.sent.single['action'], 'accept');
      final commandId = sockets.single.sent.single['command_id'];
      expect(commandId, startsWith('accept-$_tripId-'));

      // 7. The server's answer decides the session.
      sockets.single.emit(
        TripStatusChanged(status: TripStatus.accepted, raw: const {}),
      );
      async.flushMicrotasks();
      expect(
        container.read(tripSessionNotifierProvider).status,
        TripStatus.accepted,
      );

      // 8. Past the location grace: still online, dispatch socket open.
      async.elapse(const Duration(seconds: 6));
      expect(
        container.read(availabilityNotifierProvider),
        isA<AvailabilityStateOnline>(),
      );
      expect(dispatch.sink.closed, isFalse);
    });
  });

  test('a location loss that lasts past the grace still takes the driver '
      'offline', () {
    fakeAsync((async) {
      final location = _Location();
      final dispatch = TestWebSocketChannel();
      final container = ProviderContainer(
        overrides: [
          isOnlineNetworkProvider.overrideWithValue(true),
          driverProfileNotifierProvider.overrideWithBuild(
            (ref, notifier) => ProfileState.loaded(
              const DriverProfileModel(
                id: 18,
                status: DriverStatus.offline,
                approved: true,
                activeVehicle: 7,
              ),
            ),
          ),
          locationNotifierProvider.overrideWith(() => location),
          driverLocationConsumerFactoryProvider.overrideWithValue(
            () => DriverLocationConsumer(
              tokenReader: () async => 'jwt',
              positionReader: () => const LatLng(17.444, 78.381),
              wsBaseUrlReader: () => 'wss://api.example/',
              serviceFactory: (urlBuilder) => WebSocketService(
                urlBuilder: urlBuilder,
                channelFactory: (_) => dispatch,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(availabilityNotifierProvider.notifier).goOnline();
      async.flushMicrotasks();
      dispatch.incoming.add(
        '{"type":"connection_established","message":"Driver 18 connected"}',
      );
      async.flushMicrotasks();

      location.emit(const LocationState.permissionDenied(permanent: true));
      async.elapse(const Duration(seconds: 1));
      expect(
        container.read(availabilityNotifierProvider),
        isA<AvailabilityStateOnline>(),
      );

      async.elapse(const Duration(seconds: 4));
      final state = container.read(availabilityNotifierProvider);
      expect(state, isA<AvailabilityStateBlocked>());
      expect(
        (state as AvailabilityStateBlocked).reason,
        AvailabilityBlockReason.locationPermissionDenied,
      );
    });
  });
}
