import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhigo_driver/core/location/location_providers.dart';
import 'package:saaradhigo_driver/core/network/connectivity_provider.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';
import 'package:saaradhigo_driver/features/dashboard/data/data_sources/driver_location_consumer.dart';
import 'package:saaradhigo_driver/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_providers.dart';

import '../../core/network/test_websocket_channel.dart';

DriverProfileModel _profile({bool approved = true, int? activeVehicle = 7}) =>
    DriverProfileModel(
      id: 10,
      status: DriverStatus.offline,
      approved: approved,
      activeVehicle: activeVehicle,
    );

LocationState _freshLocation() => LocationState.tracking(
  position: const LatLng(17.385, 78.486),
  timestamp: DateTime.utc(2026, 8, 26, 12),
  hasBackgroundAccess: true,
);

ProviderContainer _container({
  required ProfileState profileState,
  required LocationState locationState,
  required DriverLocationConsumer Function() consumerFactory,
}) => ProviderContainer(
  overrides: [
    isOnlineNetworkProvider.overrideWithValue(true),
    driverProfileNotifierProvider.overrideWithBuild(
      (ref, notifier) => profileState,
    ),
    locationNotifierProvider.overrideWithBuild(
      (ref, notifier) => locationState,
    ),
    driverLocationConsumerFactoryProvider.overrideWithValue(consumerFactory),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('blocks an unapproved driver before creating a socket', () async {
    var consumerCreated = false;
    final container = _container(
      profileState: ProfileState.loaded(_profile(approved: false)),
      locationState: _freshLocation(),
      consumerFactory: () {
        consumerCreated = true;
        throw StateError('must not create a socket');
      },
    );
    addTearDown(container.dispose);

    await container.read(availabilityNotifierProvider.notifier).goOnline();

    final state = container.read(availabilityNotifierProvider);
    expect(state, isA<AvailabilityStateBlocked>());
    expect(
      (state as AvailabilityStateBlocked).reason,
      AvailabilityBlockReason.notApproved,
    );
    expect(consumerCreated, isFalse);
  });

  test(
    'becomes online only after backend confirmation and closes cleanly',
    () async {
      final channel = TestWebSocketChannel();
      late DriverLocationConsumer consumer;
      consumer = DriverLocationConsumer(
        tokenReader: () async => 'jwt',
        positionReader: () => const LatLng(17.385, 78.486),
        wsBaseUrlReader: () => 'wss://api.example/',
        serviceFactory: (urlBuilder) => WebSocketService(
          urlBuilder: urlBuilder,
          channelFactory: (_) => channel,
        ),
      );
      final container = _container(
        profileState: ProfileState.loaded(_profile()),
        locationState: _freshLocation(),
        consumerFactory: () => consumer,
      );
      addTearDown(container.dispose);

      final notifier = container.read(availabilityNotifierProvider.notifier);
      await notifier.goOnline();
      await pumpEventQueue();
      expect(
        container.read(availabilityNotifierProvider),
        isA<AvailabilityStateGoingOnline>(),
      );

      channel.incoming.add(
        '{"type":"connection_established","message":"Driver 10 connected"}',
      );
      await pumpEventQueue();
      expect(
        container.read(availabilityNotifierProvider),
        isA<AvailabilityStateOnline>(),
      );

      final sent = jsonDecode(channel.sink.sent.single as String);
      expect(sent, {'lat': 17.385, 'lng': 78.486});

      await notifier.goOffline();
      expect(
        container.read(availabilityNotifierProvider),
        isA<AvailabilityStateOffline>(),
      );
      expect(channel.sink.closed, isTrue);
    },
  );

  test('transitions to reconnecting when socket drops', () async {
    final channel = TestWebSocketChannel();
    final consumer = DriverLocationConsumer(
      tokenReader: () async => 'jwt',
      positionReader: () => const LatLng(17.385, 78.486),
      wsBaseUrlReader: () => 'wss://api.example/',
      serviceFactory: (urlBuilder) => WebSocketService(
        urlBuilder: urlBuilder,
        channelFactory: (_) => channel,
      ),
    );
    final container = _container(
      profileState: ProfileState.loaded(_profile()),
      locationState: _freshLocation(),
      consumerFactory: () => consumer,
    );
    addTearDown(container.dispose);

    final notifier = container.read(availabilityNotifierProvider.notifier);
    await notifier.goOnline();
    await pumpEventQueue();

    channel.incoming.add(
      '{"type":"connection_established","message":"Driver 10 connected"}',
    );
    await pumpEventQueue();
    expect(
      container.read(availabilityNotifierProvider),
      isA<AvailabilityStateOnline>(),
    );

    channel.incoming.addError('connection reset');
    await pumpEventQueue();
    expect(
      container.read(availabilityNotifierProvider),
      isA<AvailabilityStateReconnecting>(),
    );
  });
}
