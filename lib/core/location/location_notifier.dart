import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../utils/app_logger.dart';
import 'location_providers.dart';
import 'location_service.dart';

/// App-wide GPS state machine.
///
/// Lives in `core/` rather than a feature because the same stream is consumed by
/// the dashboard now and by active-trip navigation later. Mirrors the placement
/// of `core/uploads/presigned_upload_providers.dart`.
class LocationNotifier extends Notifier<LocationState> {
  late LocationService _service;

  StreamSubscription<Position>? _subscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  LocationTrackingMode _mode = LocationTrackingMode.idleOnline;
  bool _hasBackgroundAccess = false;
  Future<void>? _startFuture;

  @override
  LocationState build() {
    _service = ref.watch(locationServiceProvider);
    ref.onDispose(_teardown);
    return const LocationState.initial();
  }

  LocationTrackingMode get mode => _mode;

  /// Runs the permission/service pre-flight and starts streaming.
  ///
  /// Safe to call repeatedly — a no-op while already tracking in [mode] unless
  /// [force] is set.
  Future<void> start({
    LocationTrackingMode mode = LocationTrackingMode.idleOnline,
    bool requestPermission = true,
    bool force = false,
  }) async {
    final inFlight = _startFuture;
    if (inFlight != null) {
      await inFlight;
      if (!force && state.isTracking && _mode == mode) return;
    }
    if (!force && state.isTracking && _mode == mode) return;

    final future = _startInternal(
      mode: mode,
      requestPermission: requestPermission,
    );
    _startFuture = future;
    try {
      await future;
    } finally {
      if (identical(_startFuture, future)) _startFuture = null;
    }
  }

  Future<void> _startInternal({
    required LocationTrackingMode mode,
    required bool requestPermission,
  }) async {
    final previous = state.positionOrNull;
    _mode = mode;

    if (!state.isTracking) {
      state = const LocationState.requesting();
    }

    late final LocationAvailabilityResult result;
    try {
      result = await _service.ensureAvailable(
        requestIfNeeded: requestPermission,
      );
    } catch (error, stackTrace) {
      AppLogger.e('Location pre-flight failed', error, stackTrace);
      if (!ref.mounted) return;
      await _stopStream();
      state = const LocationState.error(
        'Unable to check location access. Please try again.',
      );
      return;
    }

    if (!ref.mounted) return;

    switch (result.availability) {
      case LocationAvailability.serviceDisabled:
        await _stopStream();
        state = const LocationState.serviceDisabled();
        return;
      case LocationAvailability.permissionDenied:
        await _stopStream();
        state = const LocationState.permissionDenied(permanent: false);
        return;
      case LocationAvailability.permissionDeniedForever:
        await _stopStream();
        state = const LocationState.permissionDenied(permanent: true);
        return;
      case LocationAvailability.ready:
        break;
    }

    _hasBackgroundAccess = result.hasBackgroundAccess;
    if (!_hasBackgroundAccess) {
      AppLogger.w(
        'Location granted as whileInUse only — dispatch while minimised '
        'will not work until background access is granted.',
      );
    }

    if (previous == null) {
      state = const LocationState.acquiring();
      // Seed the map immediately if the platform has a cached fix, so the user
      // is not staring at a spinner while the first stream event lands.
      await _seedFromLastKnown();
    }

    if (!ref.mounted) return;
    await _restartStream();
  }

  Future<void> _seedFromLastKnown() async {
    try {
      final cached = await _service.lastKnown();
      if (cached != null && state is! LocationStateTracking) {
        _emitFix(cached, weakSignal: true);
      }
    } catch (e) {
      // A missing cached fix is not an error worth surfacing.
      AppLogger.d('No cached location available: $e');
    }
  }

  Future<void> _restartStream() async {
    await _stopStream();
    if (!ref.mounted) return;

    try {
      _subscription = _service
          .watch(_mode)
          .listen(
            (position) => _emitFix(position),
            onError: (Object error) {
              AppLogger.e('Location stream error', error);
              _retainFixOrShowError();
            },
            cancelOnError: false,
          );
      _serviceStatusSubscription = _service.watchServiceStatus().listen(
        (status) {
          if (status == ServiceStatus.disabled) {
            unawaited(_handleServiceDisabled());
          } else if (state is LocationStateServiceDisabled) {
            unawaited(retry());
          }
        },
        onError: (Object error) {
          AppLogger.w('Location service status stream failed', error);
        },
      );
    } catch (error, stackTrace) {
      AppLogger.e('Location stream setup failed', error, stackTrace);
      _retainFixOrShowError();
    }
  }

  void _retainFixOrShowError() {
    if (!ref.mounted) return;
    final retained = state.positionOrNull;
    if (retained != null) {
      state = LocationState.tracking(
        position: retained,
        timestamp: DateTime.now(),
        weakSignal: true,
        hasBackgroundAccess: _hasBackgroundAccess,
      );
    } else {
      state = const LocationState.error(
        'Unable to read your location. Check that GPS is enabled.',
      );
    }
  }

  Future<void> _handleServiceDisabled() async {
    await _stopStream();
    if (ref.mounted) state = const LocationState.serviceDisabled();
  }

  void _emitFix(Position position, {bool weakSignal = false}) {
    if (!ref.mounted) return;
    state = LocationState.tracking(
      position: LatLng(position.latitude, position.longitude),
      timestamp: position.timestamp,
      heading: position.hasHeading ? position.heading : null,
      accuracy: position.hasAccuracy ? position.accuracy : null,
      weakSignal: weakSignal,
      hasBackgroundAccess: _hasBackgroundAccess,
    );
  }

  /// Switches accuracy profile (medium while idle-online, high during a trip).
  Future<void> setMode(LocationTrackingMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    if (state.isTracking) {
      await _restartStream();
    }
  }

  /// Re-runs the pre-flight after the user returns from system settings.
  Future<void> retry() =>
      start(mode: _mode, requestPermission: true, force: true);

  Future<bool> openAppSettings() => _service.openAppSettings();

  Future<bool> openLocationSettings() => _service.openLocationSettings();

  /// Stops streaming and resets to [LocationState.initial].
  Future<void> stop() async {
    await _stopStream();
    state = const LocationState.initial();
  }

  Future<void> _stopStream() async {
    final sub = _subscription;
    _subscription = null;
    final serviceStatusSub = _serviceStatusSubscription;
    _serviceStatusSubscription = null;
    await sub?.cancel();
    await serviceStatusSub?.cancel();
  }

  void _teardown() {
    _subscription?.cancel();
    _subscription = null;
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
  }
}
