import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';

/// What went wrong when we could not start tracking. Each maps to a distinct
/// recovery the driver can actually perform, which is why this is an enum
/// rather than a message string.
enum LocationDenial {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  backgroundDenied,
}

class LocationFailure implements Exception {
  const LocationFailure(this.denial, this.message);
  final LocationDenial denial;
  final String message;
  @override
  String toString() => message;
}

/// GPS acquisition and permission handling.
///
/// Deliberately transport-agnostic: it produces positions, and the duty
/// controller decides what to do with them (push over the socket, update the
/// map). That split is what lets the widget tests exercise duty logic with a
/// fake position stream and no platform channels.
class LocationService {
  LocationService();

  StreamSubscription<Position>? _sub;
  final _controller = StreamController<Position>.broadcast();

  Stream<Position> get positions => _controller.stream;

  Position? _last;
  Position? get lastKnown => _last;

  /// Ask for everything we need to run a shift, in the order Android and iOS
  /// actually require it: service on → foreground permission → background
  /// permission. Requesting background first is silently denied on Android 11+.
  Future<void> ensurePermissions({bool requireBackground = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        LocationDenial.serviceDisabled,
        'Location is switched off. Turn on GPS to go online.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationDenial.permissionDeniedForever,
        'Location permission is permanently denied. Enable it for '
        'SaaradhiGo Drive in system settings.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationDenial.permissionDenied,
        'SaaradhiGo Drive needs your location to receive ride requests.',
      );
    }

    // "Always" is what keeps dispatch alive when the screen is off. We ask
    // only after foreground access is already granted, and we do not hard-fail
    // without it — the driver can still work with the app open, and a
    // foreground service covers most of the gap.
    if (requireBackground &&
        permission == LocationPermission.whileInUse &&
        defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
        'LocationService: only while-in-use granted; background dispatch '
        'may stop when the app is not visible.',
      );
    }
  }

  Future<Position> currentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    _last = position;
    return position;
  }

  /// Begin streaming. Safe to call twice — a second call is a no-op rather
  /// than a second subscription quietly doubling the update rate.
  Future<void> start() async {
    if (_sub != null) return;

    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: AppConfig.locationDistanceFilterMeters,
            intervalDuration: AppConfig.locationInterval,
            // The persistent notification is not optional on Android 10+ for
            // background location, and on Xiaomi/Vivo/Oppo builds it is the
            // single thing that stops the OS killing the app mid-shift.
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'SaaradhiGo Drive',
              notificationText: 'You are online and receiving ride requests',
              notificationIcon:
                  AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
              enableWakeLock: true,
              setOngoing: true,
            ),
          )
        : AppleSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: AppConfig.locationDistanceFilterMeters,
            allowBackgroundLocationUpdates: true,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: true,
          );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        _last = position;
        if (!_controller.isClosed) _controller.add(position);
      },
      onError: (Object error) => debugPrint('LocationService: $error'),
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  /// Deep-links to the OS location settings so a driver who denied
  /// permanently has a one-tap route back.
  Future<void> openSystemSettings() => Geolocator.openAppSettings();
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
