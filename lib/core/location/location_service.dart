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

/// Owns all `geolocator` interaction: permission negotiation, accuracy
/// selection, and the distance-filtered position stream.
///
/// Holds no state of its own — [LocationNotifier] is the stateful consumer.
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

  /// `geolocator` throws [UnimplementedError] for permission APIs on platforms
  /// without a runtime permission model (e.g. geolocator_linux). Normalise that
  /// to [LocationPermission.unableToDetermine] so callers don't crash.
  Future<LocationPermission> _checkPermissionSafely() async {
    try {
      return await _geolocator.checkPermission();
    } on UnimplementedError {
      return LocationPermission.unableToDetermine;
    }
  }

  Future<LocationPermission> _requestPermissionSafely() async {
    try {
      return await _geolocator.requestPermission();
    } on UnimplementedError {
      return LocationPermission.unableToDetermine;
    }
  }

  LocationSettings _settingsFor(LocationTrackingMode mode) => LocationSettings(
    accuracy: mode.accuracy,
    distanceFilter: distanceFilterMeters.round(),
  );

  /// Distance-filtered stream of fixes for [mode].
  Stream<Position> watch(LocationTrackingMode mode) =>
      _geolocator.getPositionStream(_settingsFor(mode));

  Future<Position> current(LocationTrackingMode mode) =>
      _geolocator.getCurrentPosition(_settingsFor(mode));

  Future<Position?> lastKnown() => _geolocator.getLastKnownPosition();

  /// Service-status changes. Platforms without a service-status stream (the
  /// base geolocator_linux class and web) throw [UnimplementedError]; fall back
  /// to an empty stream so stream setup never fails on desktop/web.
  Stream<ServiceStatus> watchServiceStatus() {
    try {
      return _geolocator.getServiceStatusStream();
    } on UnimplementedError {
      return const Stream.empty();
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await _geolocator.openAppSettings();
    } on UnimplementedError {
      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await _geolocator.openLocationSettings();
    } on UnimplementedError {
      return false;
    }
  }
}
