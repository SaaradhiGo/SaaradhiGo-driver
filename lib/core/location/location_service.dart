import 'dart:ui' show Color;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:geolocator/geolocator.dart';

import 'geolocator_adapter.dart';

/// Outcome of a permission + service pre-flight check.
enum LocationAvailability {
  /// Service enabled and permission granted (`always` or `whileInUse`).
  ready,

  /// Device location services are switched off.
  serviceDisabled,

  /// Permission refused, but the OS will still show a prompt if asked again.
  permissionDenied,

  /// Permission refused permanently — only the app settings page can fix it.
  permissionDeniedForever,
}

/// Accuracy profile, per docs/10_LOCATION.md §2.
enum LocationTrackingMode {
  /// Online and waiting for dispatch on `/home` — battery preserving.
  idleOnline(LocationAccuracy.medium),

  /// Active trip execution (`in_progress`).
  activeTrip(LocationAccuracy.high);

  const LocationTrackingMode(this.accuracy);

  final LocationAccuracy accuracy;
}

class LocationAvailabilityResult {
  const LocationAvailabilityResult(this.availability, this.permission);

  final LocationAvailability availability;
  final LocationPermission permission;

  bool get isReady => availability == LocationAvailability.ready;

  /// True when the OS granted background ("Always") access. Not required for
  /// foreground streaming, but needed for dispatch while minimised.
  bool get hasBackgroundAccess => permission == LocationPermission.always;
}

/// Owns all `geolocator` interaction: permission negotiation and accuracy
/// selection.
///
/// The platform position stream is not distance-filtered on the web because
/// geolocator_web's `skipWhile`-based filter suppresses near-stationary fixes
/// (see [_settingsFor]); the >10 m / >5 s rule for outbound frames lives in
/// [LocationThrottle] instead. Holds no state of its own —
/// [LocationNotifier] is the stateful consumer.
class LocationService {
  LocationService(this._geolocator);

  final GeolocatorAdapter _geolocator;

  /// Minimum movement before the platform emits a new fix, per
  /// docs/10_LOCATION.md §2 (10 meters).
  static const double distanceFilterMeters = 10;

  /// Checks device location services and negotiates permission.
  ///
  /// Requests the platform's highest location grant when no permission exists.
  /// `whileInUse` is accepted as [LocationAvailability.ready] since this phase
  /// streams in the foreground only — inspect
  /// [LocationAvailabilityResult.hasBackgroundAccess] to detect the difference.
  Future<LocationAvailabilityResult> ensureAvailable({
    bool requestIfNeeded = true,
  }) async {
    final serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationAvailabilityResult(
        LocationAvailability.serviceDisabled,
        LocationPermission.denied,
      );
    }

    var permission = await _checkPermissionSafely();

    if (requestIfNeeded &&
        (permission == LocationPermission.denied ||
            permission == LocationPermission.whileInUse)) {
      permission = await _requestPermissionSafely();
    }

    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAvailabilityResult(
          LocationAvailability.ready,
          permission,
        );
      case LocationPermission.deniedForever:
        return LocationAvailabilityResult(
          LocationAvailability.permissionDeniedForever,
          permission,
        );
      case LocationPermission.denied:
        return LocationAvailabilityResult(
          LocationAvailability.permissionDenied,
          permission,
        );
      case LocationPermission.unableToDetermine:
        // No runtime permission model on this platform (geolocator_linux
        // returns unableToDetermine from checkPermission() and throws from
        // requestPermission(); the OS/GeoClue gates position access instead).
        // Treat it as permission-ready so the dashboard never shows a dead
        // "Grant Permission" button that can never advance (Phase 4 bug).
        return LocationAvailabilityResult(
          LocationAvailability.ready,
          permission,
        );
    }
  }

  /// Explicitly requests background location ("Always").
  ///
  /// On Android 11+, background location cannot be requested simultaneously
  /// with foreground location; this method requests background access after
  /// foreground access has already been granted.
  Future<LocationAvailabilityResult> requestBackgroundPermission() async {
    final serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationAvailabilityResult(
        LocationAvailability.serviceDisabled,
        LocationPermission.denied,
      );
    }

    final permission = await _requestPermissionSafely();
    switch (permission) {
      case LocationPermission.always:
        return const LocationAvailabilityResult(
          LocationAvailability.ready,
          LocationPermission.always,
        );
      case LocationPermission.whileInUse:
        return const LocationAvailabilityResult(
          LocationAvailability.ready,
          LocationPermission.whileInUse,
        );
      case LocationPermission.deniedForever:
        return const LocationAvailabilityResult(
          LocationAvailability.permissionDeniedForever,
          LocationPermission.deniedForever,
        );
      case LocationPermission.denied:
        return const LocationAvailabilityResult(
          LocationAvailability.permissionDenied,
          LocationPermission.denied,
        );
      case LocationPermission.unableToDetermine:
        return const LocationAvailabilityResult(
          LocationAvailability.ready,
          LocationPermission.unableToDetermine,
        );
    }
  }

  /// Safely queries the current OS location permission tier.
  Future<LocationPermission> checkPermission() => _checkPermissionSafely();

  /// `geolocator` throws [UnimplementedError] for permission APIs on platforms
  /// without a runtime permission model (e.g. geolocator_linux). Normalise that
  /// to [LocationPermission.unableToDetermine] so callers don't crash.
  Future<LocationPermission> _checkPermissionSafely() async {
    try {
      return await _geolocator.checkPermission();
    } on UnimplementedError {
      return LocationPermission.unableToDetermine;
    } on UnsupportedError {
      return LocationPermission.unableToDetermine;
    }
  }

  Future<LocationPermission> _requestPermissionSafely() async {
    try {
      return await _geolocator.requestPermission();
    } on UnimplementedError {
      return LocationPermission.unableToDetermine;
    } on UnsupportedError {
      return LocationPermission.unableToDetermine;
    }
  }

  LocationSettings _settingsFor(
    LocationTrackingMode mode, {
    bool enableForegroundNotification = false,
    String? notificationTitle,
    String? notificationSubtitle,
  }) {
    final distance = kIsWeb ? 0 : distanceFilterMeters.round();

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        enableForegroundNotification) {
      return AndroidSettings(
        accuracy: mode.accuracy,
        distanceFilter: distance,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle:
              notificationTitle ??
              (mode == LocationTrackingMode.activeTrip
                  ? 'SaaradhiGo Driver • On Trip'
                  : 'SaaradhiGo Driver • Online'),
          notificationText:
              notificationSubtitle ??
              (mode == LocationTrackingMode.activeTrip
                  ? 'Driving to Destination'
                  : 'Active & ready for ride dispatches'),
          notificationIcon: const AndroidResource(name: 'ic_launcher'),
          color: const Color(0xFFD4AF37),
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    return LocationSettings(
      accuracy: mode.accuracy,
      // geolocator_web implements `distanceFilter` as a `skipWhile` against the
      // previous *emitted* fix. Browsers report ~1 Hz and drivers frequently move
      // < 10 m between samples, so almost every fix is dropped and the UI never
      // leaves "acquiring". Disable the platform filter on web — the app-side
      // [LocationThrottle] (docs/10_LOCATION.md §2: >10 m or >5 s) already gates
      // outbound frames, so no backend contract is affected.
      distanceFilter: distance,
    );
  }

  /// Distance-filtered stream of fixes for [mode].
  Stream<Position> watch(
    LocationTrackingMode mode, {
    bool enableForegroundNotification = false,
    String? notificationTitle,
    String? notificationSubtitle,
  }) => _geolocator.getPositionStream(
    _settingsFor(
      mode,
      enableForegroundNotification: enableForegroundNotification,
      notificationTitle: notificationTitle,
      notificationSubtitle: notificationSubtitle,
    ),
  );

  Future<Position> current(LocationTrackingMode mode) =>
      _geolocator.getCurrentPosition(_settingsFor(mode));

  Future<Position?> lastKnown() => _geolocator.getLastKnownPosition();

  /// Service-status changes. Platforms without a service-status stream (the
  /// base geolocator_linux class and web) throw [UnimplementedError] or
  /// [UnsupportedError]; fall back to an empty stream so stream setup never
  /// fails on desktop/web.
  Stream<ServiceStatus> watchServiceStatus() {
    if (kIsWeb) return const Stream.empty();
    try {
      return _geolocator.getServiceStatusStream();
    } on UnimplementedError {
      return const Stream.empty();
    } on UnsupportedError {
      return const Stream.empty();
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await _geolocator.openAppSettings();
    } on UnimplementedError {
      return false;
    } on UnsupportedError {
      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await _geolocator.openLocationSettings();
    } on UnimplementedError {
      return false;
    } on UnsupportedError {
      return false;
    }
  }

  /// Opens settings page where battery optimization / app details can be
  /// adjusted by the driver.
  Future<bool> openBatteryOptimizationSettings() => openAppSettings();
}
