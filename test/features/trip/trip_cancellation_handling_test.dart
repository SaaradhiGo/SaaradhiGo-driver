import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/connectivity_provider.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';
import 'package:saaradhigo_driver/core/storage/local_storage_service.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip/data/data_sources/trip_status_consumer.dart';
import 'package:saaradhigo_driver/features/trip/domain/repositories/trip_repository.dart';
import 'package:saaradhigo_driver/features/trip/presentation/providers/trip_providers.dart';
import 'package:saaradhigo_driver/features/trip/presentation/widgets/ride_cancelled_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTripStatusConsumer implements TripStatusConsumer {
  _FakeTripStatusConsumer(this.tripId);

  @override
  final int tripId;

  final _eventsController = StreamController<TripStatusEvent>.broadcast();
  final _connController = StreamController<WebSocketState>.broadcast();

  bool connected = false;
  bool disposed = false;
  final List<String> sentActions = [];

  @override
  Stream<TripStatusEvent> get events => _eventsController.stream;

  @override
  Stream<WebSocketState> get connectionState => _connController.stream;

  @override
  void connect() {
    connected = true;
    _connController.add(WebSocketState.connected);
  }

  @override
  void disconnect() {
    connected = false;
    _connController.add(WebSocketState.disconnected);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _eventsController.close();
    await _connController.close();
  }

  @override
  void sendAction(String action, {String? otp, String? reason}) {
    sentActions.add(action);
  }

  @override
  void updateNetworkStatus(bool isOnline) {}

  void emitEvent(TripStatusEvent event) {
    _eventsController.add(event);
  }
}

class _FakeTripRepository implements TripRepository {
  TripModel? mockActiveTrip;
  bool shouldThrowOnActiveTrip = false;

  @override
  Future<TripModel?> getActiveTrip() async {
    if (shouldThrowOnActiveTrip) {
      throw Exception('Network / 404 error');
    }
    return mockActiveTrip;
  }

  @override
  Future<void> driverCancel(int tripId, {required String reason, String? note}) async {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  tearDown(() async {
    await LocalStorageService.clearAll();
  });

  group('Phase 12.3: Action verb normalization in TripStatusConsumer', () {
    test('tripStatusFromWsAction handles casing, whitespace, and variations', () {
      expect(tripStatusFromWsAction('cancel'), equals(TripStatus.cancelled));
      expect(tripStatusFromWsAction('CANCEL'), equals(TripStatus.cancelled));
      expect(tripStatusFromWsAction('cancelled'), equals(TripStatus.cancelled));
      expect(tripStatusFromWsAction('CANCELLED'), equals(TripStatus.cancelled));
      expect(tripStatusFromWsAction('canceled'), equals(TripStatus.cancelled));
      expect(tripStatusFromWsAction('CANCELED'), equals(TripStatus.cancelled));
      expect(tripStatusFromWsAction(' ride_cancelled '), equals(TripStatus.cancelled));

      // Other actions
      expect(tripStatusFromWsAction('ACCEPT'), equals(TripStatus.accepted));
      expect(tripStatusFromWsAction(' reached '), equals(TripStatus.reached));
      expect(tripStatusFromWsAction('START'), equals(TripStatus.inProgress));
      expect(tripStatusFromWsAction('COMPLETE'), equals(TripStatus.completed));
      expect(tripStatusFromWsAction('unknown_verb'), isNull);
    });

    test('TripStatusConsumer.parseEvent extracts cancellation and reason strings', () {
      // 1. Standard trip_status_update with 'cancelled'
      final event1 = TripStatusConsumer.parseEvent({
        'type': 'trip_status_update',
        'status': 'cancelled',
        'message': 'Rider found another cab',
      });
      expect(event1, isA<TripStatusChanged>());
      final changed1 = event1 as TripStatusChanged;
      expect(changed1.status, equals(TripStatus.cancelled));
      expect(changed1.message, equals('Rider found another cab'));

      // 2. trip_status_update with uppercase CANCELLED and 'reason' fallback
      final event2 = TripStatusConsumer.parseEvent({
        'type': 'trip_status_update',
        'status': 'CANCELLED',
        'reason': 'Passenger requested cancellation',
      });
      expect(event2, isA<TripStatusChanged>());
      final changed2 = event2 as TripStatusChanged;
      expect(changed2.status, equals(TripStatus.cancelled));
      expect(changed2.message, equals('Passenger requested cancellation'));

      // 3. Dedicated event type 'trip_cancelled'
      final event3 = TripStatusConsumer.parseEvent({
        'type': 'trip_cancelled',
        'message': 'Cancelled via backend admin',
      });
      expect(event3, isA<TripStatusChanged>());
      final changed3 = event3 as TripStatusChanged;
      expect(changed3.status, equals(TripStatus.cancelled));
      expect(changed3.message, equals('Cancelled via backend admin'));
    });
  });

  group('Phase 12.3: TripSessionNotifier cancellation handling & teardown', () {
    test('transitions to cancelled status, sets cancellationReason, and clears active trip id', () async {
      late _FakeTripStatusConsumer consumer;
      final fakeRepo = _FakeTripRepository();

      final container = ProviderContainer(
        overrides: [
          isOnlineNetworkProvider.overrideWithValue(true),
          tripStatusConsumerFactoryProvider.overrideWithValue((id) {
            consumer = _FakeTripStatusConsumer(id);
            return consumer;
          }),
          tripRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripSessionNotifierProvider.notifier);

      // Start an active trip in accepted state
      const initialTrip = TripModel(
        id: 505,
        status: TripStatus.accepted,
        pickupAddress: 'Banjara Hills',
        destinationAddress: 'Airport',
      );
      notifier.resumeActiveTrip(initialTrip);

      var state = container.read(tripSessionNotifierProvider);
      expect(state.isActive, isTrue);
      expect(state.status, equals(TripStatus.accepted));
      expect(LocalStorageService.getActiveTripId(), equals('505'));

      // Emit cancellation event over socket
      consumer.emitEvent(const TripStatusChanged(
        status: TripStatus.cancelled,
        message: 'Rider cancelled due to delay',
        raw: {'type': 'trip_status_update', 'status': 'cancelled'},
      ));
      await Future<void>.delayed(Duration.zero);

      state = container.read(tripSessionNotifierProvider);
      // Status is cancelled
      expect(state.status, equals(TripStatus.cancelled));
      // Reason captured
      expect(state.cancellationReason, equals('Rider cancelled due to delay'));
      // Route guard flags
      expect(state.isTerminal, isTrue);
      expect(state.isActive, isFalse);
      // Consumer detached and active trip id cleared
      expect(LocalStorageService.getActiveTripId(), isNull);
    });

    test('checkActiveTripOnResume transitions active session to cancelled when backend returns terminal/null', () async {
      late _FakeTripStatusConsumer consumer;
      final fakeRepo = _FakeTripRepository();

      final container = ProviderContainer(
        overrides: [
          isOnlineNetworkProvider.overrideWithValue(true),
          tripStatusConsumerFactoryProvider.overrideWithValue((id) {
            consumer = _FakeTripStatusConsumer(id);
            return consumer;
          }),
          tripRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripSessionNotifierProvider.notifier);

      // In active session
      const initialTrip = TripModel(
        id: 707,
        status: TripStatus.inProgress,
        pickupAddress: 'Madhapur',
        destinationAddress: 'Secunderabad',
      );
      notifier.resumeActiveTrip(initialTrip);

      expect(container.read(tripSessionNotifierProvider).isActive, isTrue);

      // Backend now returns cancelled trip
      fakeRepo.mockActiveTrip = const TripModel(
        id: 707,
        status: TripStatus.cancelled,
      );

      await notifier.checkActiveTripOnResume();

      final state = container.read(tripSessionNotifierProvider);
      expect(state.status, equals(TripStatus.cancelled));
      expect(state.isTerminal, isTrue);
      expect(state.isActive, isFalse);
      expect(state.cancellationReason, contains('cancelled by the passenger'));
      expect(LocalStorageService.getActiveTripId(), isNull);
    });
  });

  group('Phase 12.3: RideCancelledBottomSheet widget test', () {
    testWidgets('renders cancellation modal and triggers onDismiss', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RideCancelledBottomSheet(
              reason: 'Customer changed plans',
              autoDismissSeconds: 0, // disable countdown during tap test
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Ride Cancelled by Passenger'), findsOneWidget);
      expect(find.text('Customer changed plans'), findsOneWidget);
      expect(find.text('RETURN TO DASHBOARD'), findsOneWidget);

      await tester.tap(find.text('RETURN TO DASHBOARD'));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}
