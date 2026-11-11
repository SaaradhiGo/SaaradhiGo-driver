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

  /// When true, getServiceStatusStream behaves like geolocator_web and throws
  /// [UnsupportedError].
  bool simulateUnsupportedServiceStatus = false;

  LocationSettings? lastSettings;
  int appSettingsOpened = 0;

  final positions = StreamController<Position>.broadcast();
  final serviceStatuses = StreamController<ServiceStatus>.broadcast();

  @override
  Future<LocationPermission> checkPermission() async {
    if (simulateLinux) return LocationPermission.unableToDetermine;
    return checkedPermission;
  }

  @override
  Stream<Position> getPositionStream(LocationSettings settings) {
    lastSettings = settings;
    return positions.stream;
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() {
    if (simulateUnsupportedServiceStatus) {
      throw UnsupportedError(
        'getServiceStatusStream is not supported on the web platform.',
      );
    }
    return serviceStatuses.stream;
  }

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
    appSettingsOpened++;
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

  test('transitions to tracking on near-stationary fixes — guards the web '
      'distanceFilter regression', () async {
    // Regression: geolocator_web 4.1.x implements distanceFilter as a
    // skipWhile over consecutive fixes, so with a 10 m filter the browser
    // (~1 Hz samples, often < 10 m apart) suppresses almost every fix and the
    // notifier never leaves "acquiring". The app must reach tracking for
    // sub-filter movement; the outbound WebSocket frame gate
    // (LocationThrottle, docs/10_LOCATION.md §2) remains the only place that
    // enforces the >10 m / >5 s rule.
    final notifier = container.read(locationNotifierProvider.notifier);
    await notifier.start();

    // Two fixes ~3 m apart — well under the 10 m platform distanceFilter.
    geolocator.positions.add(_position(lat: 17.3850));
    await pumpEventQueue();
    expect(
      container.read(locationNotifierProvider),
      isA<LocationStateTracking>(),
    );

    geolocator.positions.add(_position(lat: 17.38503));
    await pumpEventQueue();
    final state = container.read(locationNotifierProvider);
    expect(state, isA<LocationStateTracking>());
    expect((state as LocationStateTracking).position.latitude, 17.38503);
  });

  test(
    'watchServiceStatus returns empty stream on UnsupportedError (web platform)',
    () async {
      geolocator.simulateUnsupportedServiceStatus = true;

      final notifier = container.read(locationNotifierProvider.notifier);
      await notifier.start();

      expect(
        container.read(locationNotifierProvider),
        isA<LocationStateAcquiring>(),
      );

      geolocator.positions.add(_position());
      await pumpEventQueue();

      expect(
        container.read(locationNotifierProvider),
        isA<LocationStateTracking>(),
      );
    },
  );

  test(
    'setForegroundNotification configures foreground service and updates stream',
    () async {
      final notifier = container.read(locationNotifierProvider.notifier);
      await notifier.start(enableForegroundService: false);
      geolocator.positions.add(_position());
      await pumpEventQueue();

      expect(notifier.enableForegroundService, isFalse);

      await notifier.setForegroundNotification(
        enabled: true,
        title: 'SaaradhiGo Driver • Online',
        subtitle: 'Active & ready for ride dispatches',
      );
      await pumpEventQueue();

      expect(notifier.enableForegroundService, isTrue);
    },
  );

  test(
    'updateNotificationText updates notification text while tracking',
    () async {
      final notifier = container.read(locationNotifierProvider.notifier);
      await notifier.start(enableForegroundService: true);
      geolocator.positions.add(_position());
      await pumpEventQueue();

      await notifier.updateNotificationText(
        subtitle: 'Reconnecting to dispatch...',
      );
      await pumpEventQueue();

      expect(
        container.read(locationNotifierProvider),
        isA<LocationStateTracking>(),
      );
    },
  );

  test('requestBackgroundPermission updates hasBackgroundAccess', () async {
    geolocator.checkedPermission = LocationPermission.whileInUse;
    geolocator.requestedPermission = LocationPermission.whileInUse;

    final notifier = container.read(locationNotifierProvider.notifier);
    await notifier.start();
    geolocator.positions.add(_position());
    await pumpEventQueue();

    expect(notifier.hasBackgroundAccess, isFalse);

    geolocator.requestedPermission = LocationPermission.always;
    final result = await notifier.requestBackgroundPermission();
    expect(result.hasBackgroundAccess, isTrue);
    expect(notifier.hasBackgroundAccess, isTrue);

    final state = container.read(locationNotifierProvider);
    expect(state, isA<LocationStateTracking>());
    expect((state as LocationStateTracking).hasBackgroundAccess, isTrue);
  });

  test(
    'openBatteryOptimizationSettings delegates to adapter app settings',
    () async {
      final notifier = container.read(locationNotifierProvider.notifier);
      final opened = await notifier.openBatteryOptimizationSettings();
      expect(opened, isTrue);
      expect(geolocator.appSettingsOpened, 1);
    },
  );

  test(
    'refreshPermissions updates hasBackgroundAccess to true on upgrade to always',
    () async {
      geolocator.checkedPermission = LocationPermission.whileInUse;
      geolocator.requestedPermission = LocationPermission.whileInUse;

      final notifier = container.read(locationNotifierProvider.notifier);
      await notifier.start();
      geolocator.positions.add(_position());
      await pumpEventQueue();

      expect(notifier.hasBackgroundAccess, isFalse);
      expect(
        (container.read(locationNotifierProvider) as LocationStateTracking)
            .hasBackgroundAccess,
        isFalse,
      );

      // Simulate user toggling to "Allow all the time" in system settings
      geolocator.checkedPermission = LocationPermission.always;
      await notifier.refreshPermissions();
      await pumpEventQueue();

      expect(notifier.hasBackgroundAccess, isTrue);
      expect(
        (container.read(locationNotifierProvider) as LocationStateTracking)
            .hasBackgroundAccess,
        isTrue,
      );
    },
  );

  test(
    'refreshPermissions updates hasBackgroundAccess to false on downgrade to whileInUse',
    () async {
      geolocator.checkedPermission = LocationPermission.always;
      geolocator.requestedPermission = LocationPermission.always;

      final notifier = container.read(locationNotifierProvider.notifier);
      await notifier.start();
      geolocator.positions.add(_position());
      await pumpEventQueue();

      expect(notifier.hasBackgroundAccess, isTrue);

      // Simulate user toggling back to "While using the app"
      geolocator.checkedPermission = LocationPermission.whileInUse;
      await notifier.refreshPermissions();
      await pumpEventQueue();

      expect(notifier.hasBackgroundAccess, isFalse);
      expect(
        (container.read(locationNotifierProvider) as LocationStateTracking)
            .hasBackgroundAccess,
        isFalse,
      );
    },
  );

  test(
    'refreshPermissions stops stream and transitions to permissionDenied when revoked',
    () async {
      geolocator.checkedPermission = LocationPermission.whileInUse;

      final notifier = container.read(locationNotifierProvider.notifier);
      await notifier.start();
      geolocator.positions.add(_position());
      await pumpEventQueue();

      expect(
        container.read(locationNotifierProvider),
        isA<LocationStateTracking>(),
      );

      // Simulate user revoking permission in system settings
      geolocator.checkedPermission = LocationPermission.deniedForever;
      await notifier.refreshPermissions();
      await pumpEventQueue();

      final state = container.read(locationNotifierProvider);
      expect(state, isA<LocationStatePermissionDenied>());
      expect((state as LocationStatePermissionDenied).permanent, isTrue);
      expect(notifier.hasBackgroundAccess, isFalse);
    },
  );
}
