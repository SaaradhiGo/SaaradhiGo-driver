import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';
import 'package:saaradhigo_driver/core/storage/local_storage_service.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip/data/data_sources/trip_status_consumer.dart';
import 'package:saaradhigo_driver/features/trip/presentation/providers/trip_providers.dart';

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
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  tearDown(() async {
    await LocalStorageService.clearAll();
  });

  group('TripSessionNotifier - resumeActiveTrip & ActiveRide state', () {
    test('resumes in-progress trip and sets isActive to true', () {
      late _FakeTripStatusConsumer consumer;
      final container = ProviderContainer(
        overrides: [
          tripStatusConsumerFactoryProvider.overrideWithValue((id) {
            consumer = _FakeTripStatusConsumer(id);
            return consumer;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripSessionNotifierProvider.notifier);
      const trip = TripModel(
        id: 101,
        status: TripStatus.inProgress,
        pickupAddress: 'Pickup Point',
        destinationAddress: 'Dropoff Point',
      );

      notifier.resumeActiveTrip(trip);

      final state = container.read(tripSessionNotifierProvider);
      expect(state.isActive, isTrue);
      expect(state.isTerminal, isFalse);
      expect(state.status, equals(TripStatus.inProgress));
      expect(state.trip?.id, equals(101));
      expect(consumer.connected, isTrue);
      expect(LocalStorageService.getActiveTripId(), equals('101'));
    });

    test(
      'normalizes requested trip on resume to accepted so driver lands on pickup navigation',
      () {
        late _FakeTripStatusConsumer consumer;
        final container = ProviderContainer(
          overrides: [
            tripStatusConsumerFactoryProvider.overrideWithValue((id) {
              consumer = _FakeTripStatusConsumer(id);
              return consumer;
            }),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(tripSessionNotifierProvider.notifier);
        const trip = TripModel(
          id: 202,
          status: TripStatus.requested,
          driverId: 15,
        );

        notifier.resumeActiveTrip(trip);

        final state = container.read(tripSessionNotifierProvider);
        expect(state.isActive, isTrue);
        expect(state.status, equals(TripStatus.accepted));
        expect(state.trip?.id, equals(202));
        expect(consumer.connected, isTrue);
      },
    );

    test('does not resume terminal completed trip', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tripSessionNotifierProvider.notifier);
      const trip = TripModel(id: 303, status: TripStatus.completed);

      notifier.resumeActiveTrip(trip);

      final state = container.read(tripSessionNotifierProvider);
      expect(state.isActive, isFalse);
      expect(state.trip, isNull);
    });
  });
}
