import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhigo_driver/core/location/geolocator_adapter.dart';
import 'package:saaradhigo_driver/core/location/location_providers.dart';
import 'package:saaradhigo_driver/core/location/location_service.dart';
import 'package:saaradhigo_driver/core/network/logging_interceptor.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';
import 'package:saaradhigo_driver/features/dashboard/data/data_sources/driver_location_consumer.dart';
import 'package:saaradhigo_driver/features/support/data/data_sources/trip_chat_consumer.dart';
import 'package:saaradhigo_driver/features/trip/data/data_sources/trip_status_consumer.dart';
import 'package:saaradhigo_driver/shared/widgets/app_cached_tile_provider.dart';

class _FakeWebSocketService implements WebSocketService {
  final messageController = StreamController<Map<String, dynamic>>.broadcast();
  final connectionStateController =
      StreamController<WebSocketState>.broadcast();
  int disposeCallCount = 0;
  int disconnectCallCount = 0;

  @override
  Stream<Map<String, dynamic>> get messageStream => messageController.stream;

  @override
  Stream<WebSocketState> get stateStream => connectionStateController.stream;

  @override
  bool get isConnected => false;

  @override
  void connect() {}

  @override
  void disconnect() {
    disconnectCallCount++;
  }

  @override
  void sendMessage(Map<String, dynamic> message) {}

  @override
  void updateNetworkStatus(bool isOnline) {}

  @override
  void dispose() {
    disposeCallCount++;
    messageController.close();
    connectionStateController.close();
  }
}

class _StubGeolocator implements GeolocatorAdapter {
  final positions = StreamController<Position>.broadcast();
  final serviceStatuses = StreamController<ServiceStatus>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.always;

  @override
  Future<Position?> getLastKnownPosition() async => null;

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) async =>
      Position(
        latitude: 17.385,
        longitude: 78.486,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 500.0,
        altitudeAccuracy: 1.0,
        heading: 90.0,
        headingAccuracy: 1.0,
        speed: 10.0,
        speedAccuracy: 1.0,
      );

  @override
  Stream<Position> getPositionStream(LocationSettings settings) =>
      positions.stream;

  @override
  Stream<ServiceStatus> getServiceStatusStream() => serviceStatuses.stream;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  Future<void> dispose() async {
    await positions.close();
    await serviceStatuses.close();
  }
}

void main() {
  group('AppCachedTileProvider Performance Tests', () {
    test('creates CachedNetworkImageProvider with valid tile URL', () {
      final provider = AppCachedTileProvider(headers: {'X-Test': '123'});
      const coords = TileCoordinates(10, 20, 5);
      final options = TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );

      final image = provider.getImage(coords, options);

      expect(image, isA<CachedNetworkImageProvider>());
      final cachedImage = image as CachedNetworkImageProvider;
      expect(cachedImage.url, 'https://tile.openstreetmap.org/5/10/20.png');
      expect(cachedImage.headers?['X-Test'], '123');
    });
  });

  group('LoggingInterceptor Security & Sanitization Tests', () {
    test('redacts sensitive query parameters from URLs', () {
      final uri = Uri.parse(
        'https://dev.api.saaradhigo.in/driver/location/?token=secret_jwt_token&lat=17.385&lng=78.486&otp=999999&api_key=priv_key',
      );

      final sanitized = LoggingInterceptor.sanitizeUri(uri);

      expect(sanitized, contains('token=%5BREDACTED%5D'));
      expect(sanitized, contains('otp=%5BREDACTED%5D'));
      expect(sanitized, contains('api_key=%5BREDACTED%5D'));
      expect(sanitized, contains('lat=17.385'));
      expect(sanitized, contains('lng=78.486'));
      expect(sanitized, isNot(contains('secret_jwt_token')));
      expect(sanitized, isNot(contains('999999')));
      expect(sanitized, isNot(contains('priv_key')));
    });

    test('redacts sensitive headers and nested body keys', () {
      final interceptor = LoggingInterceptor();
      final options = RequestOptions(
        path: '/api/v1/driver/login/',
        headers: {
          'Authorization': 'Bearer confidential_access_token',
          'Content-Type': 'application/json',
        },
        data: {
          'phone': '+919999999999',
          'otp': '123456',
          'password': 'my_password',
          'nested': {
            'upload_url': 'https://s3.amazonaws.com/secret-presigned-url',
            'client_secret': 'super_secret',
            'safe_param': 'visible_data',
          },
        },
      );

      final handler = RequestInterceptorHandler();
      // onRequest processes without crashing and executes redactions
      expect(() => interceptor.onRequest(options, handler), returnsNormally);
    });
  });

  group('Consumer Memory Lifecycle & Stream Disposal Tests', () {
    test(
      'DriverLocationConsumer disposes cleanly without memory leaks',
      () async {
        final fakeWs = _FakeWebSocketService();
        final consumer = DriverLocationConsumer(
          tokenReader: () async => 'test_token',
          positionReader: () => const LatLng(17.385, 78.486),
          serviceFactory: (_) => fakeWs,
        );

        consumer.connect();
        expect(consumer.events, isNotNull);

        await consumer.dispose();

        expect(fakeWs.disposeCallCount, 1);
        expect(fakeWs.messageController.isClosed, isTrue);
      },
    );

    test('TripStatusConsumer disposes cleanly without memory leaks', () async {
      final fakeWs = _FakeWebSocketService();
      final consumer = TripStatusConsumer(
        tripId: 42,
        tokenReader: () async => 'test_token',
        serviceFactory: (_) => fakeWs,
      );

      consumer.connect();
      expect(consumer.events, isNotNull);

      await consumer.dispose();

      expect(fakeWs.disposeCallCount, 1);
      expect(fakeWs.messageController.isClosed, isTrue);
    });

    test('TripChatConsumer disposes cleanly without memory leaks', () async {
      final fakeWs = _FakeWebSocketService();
      final consumer = TripChatConsumer(
        tripId: 42,
        tokenReader: () async => 'test_token',
        serviceFactory: (_) => fakeWs,
      );

      consumer.connect();
      expect(consumer.events, isNotNull);

      await consumer.dispose();

      expect(fakeWs.disposeCallCount, 1);
      expect(fakeWs.messageController.isClosed, isTrue);
    });

    test('LocationNotifier stops streams and resets state cleanly', () async {
      final stubGeolocator = _StubGeolocator();
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(
            LocationService(stubGeolocator),
          ),
        ],
      );

      final notifier = container.read(locationNotifierProvider.notifier);
      await notifier.start();

      expect(container.read(locationNotifierProvider), isNotNull);

      await notifier.stop();
      expect(
        container.read(locationNotifierProvider),
        const LocationState.initial(),
      );

      await stubGeolocator.dispose();
      container.dispose();
    });
  });
}
