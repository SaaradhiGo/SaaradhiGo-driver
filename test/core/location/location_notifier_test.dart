import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:saaradhigo_driver/core/location/geolocator_adapter.dart';
import 'package:saaradhigo_driver/core/location/location_providers.dart';
import 'package:saaradhigo_driver/core/location/location_service.dart';

class _FakeGeolocator implements GeolocatorAdapter {
  bool serviceEnabled = true;
  LocationPermission checkedPermission = LocationPermission.always;
  LocationPermission requestedPermission = LocationPermission.always;
  Position? cached;
  int permissionRequests = 0;

  /// When true, permission APIs behave like geolocator_linux: checkPermission
  /// returns `unableToDetermine` and requestPermission throws
  /// [UnimplementedError].
  bool simulateLinux = false;

  /// When true, openAppSettings/openLocationSettings behave like
  /// geolocator_linux/web and throw [UnimplementedError].
  bool simulateUnsupportedSettings = false;

  final positions = StreamController<Position>.broadcast();
  final serviceStatuses = StreamController<ServiceStatus>.broadcast();

  @override
  Future<LocationPermission> checkPermission() async {
    if (simulateLinux) return LocationPermission.unableToDetermine;
    return checkedPermission;
  }

  @override
  Stream<Position> getPositionStream(LocationSettings settings) =>
      positions.stream;

  @override
  Stream<ServiceStatus> getServiceStatusStream() => serviceStatuses.stream;

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) async =>
      cached ?? _position();

  @override
  Future<Position?> getLastKnownPosition() async => cached;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openAppSettings() async {
    if (simulateUnsupportedSettings) {
      throw UnimplementedError('openAppSettings() has not been implemented.');
    }
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    if (simulateUnsupportedSettings) {
      throw UnimplementedError(
        'openLocationSettings() has not been implemented.',
      );
    }
    return true;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    if (simulateLinux) {
      throw UnimplementedError('requestPermission() has not been implemented.');
    }
    permissionRequests++;
    return requestedPermission;
  }

  Future<void> dispose() async {
    await positions.close();
    await serviceStatuses.close();
  }
}

Position _position({double lat = 17.3850, double lng = 78.4867}) => Position(
  longitude: lng,
  latitude: lat,
  timestamp: DateTime.utc(2026, 8, 26, 12),
  accuracy: 4,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 45,
  headingAccuracy: 2,
  speed: 0,
  speedAccuracy: 0,
  hasAccuracy: true,
  hasHeading: true,
);

void main() {
  late _FakeGeolocator geolocator;
  late ProviderContainer container;

  setUp(() {
    geolocator = _FakeGeolocator();
    container = ProviderContainer(
      overrides: [geolocatorAdapterProvider.overrideWithValue(geolocator)],
    );
    addTearDown(() async {
      container.dispose();
      await geolocator.dispose();
    });
  });

  test('reports disabled device location services', () async {
    geolocator.serviceEnabled = false;

    await container.read(locationNotifierProvider.notifier).start();

    expect(
      container.read(locationNotifierProvider),
      isA<LocationStateServiceDisabled>(),
    );
  });

  test('reports a permanently denied permission', () async {
    geolocator.checkedPermission = LocationPermission.denied;
    geolocator.requestedPermission = LocationPermission.deniedForever;

    await container.read(locationNotifierProvider.notifier).start();

    final state = container.read(locationNotifierProvider);
    expect(state, isA<LocationStatePermissionDenied>());
    expect((state as LocationStatePermissionDenied).permanent, isTrue);
    expect(geolocator.permissionRequests, 1);
  });

  test('streams a fresh fix and reacts when GPS is disabled', () async {
    final notifier = container.read(locationNotifierProvider.notifier);
    await notifier.start();
    expect(
      container.read(locationNotifierProvider),
      isA<LocationStateAcquiring>(),
    );

    geolocator.positions.add(_position());
    await pumpEventQueue();

    final tracking = container.read(locationNotifierProvider);
    expect(tracking, isA<LocationStateTracking>());
    expect((tracking as LocationStateTracking).position.latitude, 17.3850);
    expect(tracking.hasBackgroundAccess, isTrue);

    geolocator.serviceStatuses.add(ServiceStatus.disabled);
    await pumpEventQueue();
    expect(
      container.read(locationNotifierProvider),
      isA<LocationStateServiceDisabled>(),
    );
  });

  test(
    'retains a cached fix as weak until the stream produces a fresh fix',
    () async {
      geolocator.cached = _position(lat: 17.4);

      await container.read(locationNotifierProvider.notifier).start();

      final cached = container.read(locationNotifierProvider);
      expect(cached, isA<LocationStateTracking>());
      expect((cached as LocationStateTracking).weakSignal, isTrue);

      geolocator.positions.add(_position(lat: 17.41));
      await pumpEventQueue();
      final fresh = container.read(locationNotifierProvider);
      expect((fresh as LocationStateTracking).weakSignal, isFalse);
      expect(fresh.position.latitude, 17.41);
    },
  );

  test('treats unableToDetermine as ready so Linux never shows a dead '
      '"Grant Permission" button', () async {
    geolocator.simulateLinux = true;

    final notifier = container.read(locationNotifierProvider.notifier);
    await notifier.start();

    final state = container.read(locationNotifierProvider);
    // Not stuck on permissionDenied; proceeds to acquire/track.
    expect(state, isNot(isA<LocationStatePermissionDenied>()));
    expect(geolocator.permissionRequests, 0);

    geolocator.positions.add(_position());
    await pumpEventQueue();
    expect(
      container.read(locationNotifierProvider),
      isA<LocationStateTracking>(),
    );
  });

  test('open settings returns false instead of throwing when unsupported', () {
    geolocator.simulateUnsupportedSettings = true;

    final service = LocationService(geolocator);

    expect(service.openAppSettings(), completion(isFalse));
    expect(service.openLocationSettings(), completion(isFalse));
  });
}
