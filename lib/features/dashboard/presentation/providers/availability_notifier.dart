import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/location/location_throttle.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/driver_profile_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/data_sources/driver_location_consumer.dart';
import 'dashboard_providers.dart';

/// Cadence of the keep-alive location push.
///
/// The platform position stream is distance-filtered (10 m), so a stationary
/// driver produces no events. docs/10_LOCATION.md §2 also requires a push when
/// more than 5 seconds have elapsed, so a timer re-sends the last known fix.
const Duration kLocationHeartbeat = Duration(seconds: 5);

/// Owns the driver location socket and therefore the driver's online status.
class AvailabilityNotifier extends Notifier<AvailabilityState> {
  DriverLocationConsumer? _consumer;
  StreamSubscription<DriverLocationEvent>? _eventSubscription;
  StreamSubscription<WebSocketState>? _connectionSubscription;
  Timer? _heartbeat;

  final LocationThrottle _throttle = LocationThrottle(
    minDistanceMeters: 10,
    minInterval: kLocationHeartbeat,
  );

  /// The driver's *intent*, independent of transport state. Distinguishes a
  /// genuine drop (reconnect) from a deliberate disconnect (stay offline).
  bool _intendsOnline = false;
  bool _runningOnlinePreflight = false;
  int _preflightGeneration = 0;

  final _rideRequestController =
      StreamController<DriverLocationRideRequest>.broadcast();

  /// Inbound ride requests. Phase 4 only logs these; Phase 5 renders the modal.
  Stream<DriverLocationRideRequest> get rideRequests =>
      _rideRequestController.stream;

  @override
  AvailabilityState build() {
    ref.listen<LocationState>(
      locationNotifierProvider,
      (_, next) => _onLocationChanged(next),
    );
    // Pause/resume the socket's reconnect budget with platform connectivity so
    // airplane mode never exhausts the backoff (docs/14_ERROR_HANDLING.md:18).
    ref.listen<bool>(isOnlineNetworkProvider, (previous, next) {
      if (previous == next) return;
      _consumer?.updateNetworkStatus(next);
    });
    ref.onDispose(_teardown);
    return const AvailabilityState.offline();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> toggle() =>
      state.isEngaged || state.isTransitioning ? goOffline() : goOnline();

  /// Runs the pre-flight guard chain and, if it passes, opens the socket.
  Future<void> goOnline() async {
    if (state.isEngaged || _runningOnlinePreflight) return;
    _runningOnlinePreflight = true;
    final generation = ++_preflightGeneration;

    try {
      final block = await _runPreflight();
      if (!ref.mounted || generation != _preflightGeneration) return;
      if (block != null) {
        state = block;
        return;
      }

      _intendsOnline = true;
      _throttle.reset();
      state = const AvailabilityState.goingOnline();

      unawaited(
        ref
            .read(locationNotifierProvider.notifier)
            .setForegroundNotification(
              enabled: true,
              title: 'SaaradhiGo Driver • Online',
              subtitle: 'Active & ready for ride dispatches',
            ),
      );

      _attachConsumer();
      _consumer!.connect();
    } catch (error, stackTrace) {
      AppLogger.e('Unable to start driver availability', error, stackTrace);
      if (ref.mounted && generation == _preflightGeneration) {
        _intendsOnline = false;
        unawaited(
          ref
              .read(locationNotifierProvider.notifier)
              .setForegroundNotification(enabled: false),
        );
        await _detachConsumer();
        state = const AvailabilityState.error(
          'Unable to connect to dispatch. Please try again.',
        );
      }
    } finally {
      _runningOnlinePreflight = false;
    }
  }

  /// Closes the socket. This *is* going offline — there is no REST endpoint and
  /// no documented client-side "go offline" message.
  Future<void> goOffline() async {
    if (!_intendsOnline &&
        state is AvailabilityStateOffline &&
        !_runningOnlinePreflight) {
      return;
    }

    _preflightGeneration++;
    _intendsOnline = false;
    state = const AvailabilityState.goingOffline();

    unawaited(
      ref
          .read(locationNotifierProvider.notifier)
          .setForegroundNotification(enabled: false),
    );

    _stopHeartbeat();
    await _detachConsumer();

    state = const AvailabilityState.offline();
  }

  /// Clears a `blocked` / `error` state back to `offline` so the toggle is
  /// usable again once the user has fixed the cause.
  void acknowledge() {
    if (state is AvailabilityStateBlocked || state is AvailabilityStateError) {
      state = const AvailabilityState.offline();
    }
  }

  // ---------------------------------------------------------------------------
  // Pre-flight guards
  // ---------------------------------------------------------------------------

  /// Returns a blocking state, or null when the driver may go online.
  ///
  /// Order mirrors the legacy dashboard guard chain, but surfaces blocking
  /// modals for location problems per docs/10_LOCATION.md §4 instead of
  /// transient snackbars.
  Future<AvailabilityState?> _runPreflight() async {
    if (!ref.read(isOnlineNetworkProvider)) {
      return const AvailabilityState.blocked(
        reason: AvailabilityBlockReason.noNetwork,
        message: 'No internet connection. Reconnect to go online.',
      );
    }

    var profileState = ref.read(driverProfileNotifierProvider);
    if (profileState is ProfileStateInitial ||
        profileState is ProfileStateError) {
      await ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
      profileState = ref.read(driverProfileNotifierProvider);
    }

    switch (profileState) {
      case ProfileStateLoading():
      case ProfileStateInitial():
        return const AvailabilityState.blocked(
          reason: AvailabilityBlockReason.profileLoading,
          message: 'Loading your profile. Please wait…',
        );
      case ProfileStateError(:final message):
        return AvailabilityState.blocked(
          reason: AvailabilityBlockReason.profileUnavailable,
          message: 'Could not load your profile: $message',
        );
      case ProfileStateLoaded(:final profile):
        final profileBlock = _guardProfile(profile);
        if (profileBlock != null) return profileBlock;
    }

    return _guardLocation();
  }

  AvailabilityState? _guardProfile(DriverProfileModel profile) {
    if (!profile.approved) {
      return const AvailabilityState.blocked(
        reason: AvailabilityBlockReason.notApproved,
        message:
            'Your documents are pending verification. '
            'You can go online once approved.',
      );
    }

    final hasVehicle =
        profile.activeVehicle != null || profile.activeVehicleDetails != null;
    if (!hasVehicle) {
      return const AvailabilityState.blocked(
        reason: AvailabilityBlockReason.noActiveVehicle,
        message: 'Add an active vehicle before going online.',
      );
    }

    return null;
  }

  Future<AvailabilityState?> _guardLocation() async {
    final locationNotifier = ref.read(locationNotifierProvider.notifier);

    if (!ref.read(locationNotifierProvider).isTracking) {
      await locationNotifier.start();
    }

    final locationState = ref.read(locationNotifierProvider);

    switch (locationState) {
      case LocationStateTracking():
        return null;
      case LocationStateServiceDisabled():
        return const AvailabilityState.blocked(
          reason: AvailabilityBlockReason.locationServiceDisabled,
          message: 'Turn on device location services to go online.',
        );
      case LocationStatePermissionDenied():
        return const AvailabilityState.blocked(
          reason: AvailabilityBlockReason.locationPermissionDenied,
          message: 'Location permission is required to receive ride requests.',
        );
      case LocationStateError(:final message):
        return AvailabilityState.blocked(
          reason: AvailabilityBlockReason.awaitingGpsFix,
          message: message,
        );
      case LocationStateInitial():
      case LocationStateRequesting():
      case LocationStateAcquiring():
        return const AvailabilityState.blocked(
          reason: AvailabilityBlockReason.awaitingGpsFix,
          message: 'Getting your location. Please wait…',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Socket wiring
  // ---------------------------------------------------------------------------

  void _attachConsumer() {
    if (_consumer != null) return;

    final consumer = ref.read(driverLocationConsumerFactoryProvider)();
    _consumer = consumer;

    _eventSubscription = consumer.events.listen(_onEvent);
    _connectionSubscription = consumer.connectionState.listen(
      _onConnectionState,
    );
  }

  Future<void> _detachConsumer() async {
    final consumer = _consumer;
    _consumer = null;
    final eventSubscription = _eventSubscription;
    _eventSubscription = null;
    final connectionSubscription = _connectionSubscription;
    _connectionSubscription = null;

    await eventSubscription?.cancel();
    await connectionSubscription?.cancel();

    if (consumer != null) {
      consumer.disconnect();
      await consumer.dispose();
    }
  }

  void _onEvent(DriverLocationEvent event) {
    switch (event) {
      case DriverLocationConnectionEstablished(:final message):
        AppLogger.i('Driver online: $message');
        if (!_intendsOnline) return;
        state = AvailabilityState.online(since: DateTime.now());
        _startHeartbeat();
        _pushCurrentPosition(force: true);

      case DriverLocationUpdated(:final lat, :final lng):
        AppLogger.d('Location ack: $lat, $lng');

      case DriverLocationRideRequest():
        // Phase 5 owns the incoming-request UI. Surfaced on a stream and logged
        // so the wiring is verifiable without inventing navigation.
        AppLogger.i('Ride request received (trip ${event.tripId})');
        if (!_rideRequestController.isClosed) {
          _rideRequestController.add(event);
        }

      case DriverLocationUnknownEvent(:final type):
        AppLogger.w('Unhandled driver location event type: $type');
    }
  }

  void _onConnectionState(WebSocketState wsState) {
    if (!_intendsOnline) return;

    switch (wsState) {
      case WebSocketState.connecting:
      case WebSocketState.connected:
        // Transport is up, but the backend only counts us online once
        // `connection_established` arrives.
        if (state is! AvailabilityStateOnline) {
          state = const AvailabilityState.goingOnline();
        }
        unawaited(
          ref
              .read(locationNotifierProvider.notifier)
              .updateNotificationText(
                subtitle: 'Active & ready for ride dispatches',
              ),
        );

      case WebSocketState.disconnected:
        _stopHeartbeat();
        state = const AvailabilityState.reconnecting();
        unawaited(
          ref
              .read(locationNotifierProvider.notifier)
              .updateNotificationText(subtitle: 'Reconnecting to dispatch...'),
        );

      case WebSocketState.error:
        // Backoff exhausted. Fall back to offline per
        // docs/21_NAVIGATION_USER_FLOW_SPECIFICATION.md:109.
        _intendsOnline = false;
        _stopHeartbeat();
        unawaited(
          ref
              .read(locationNotifierProvider.notifier)
              .setForegroundNotification(enabled: false),
        );
        unawaited(_detachConsumer());
        state = const AvailabilityState.error(
          'Lost connection to dispatch. You are offline — tap to retry.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Location streaming
  // ---------------------------------------------------------------------------

  void _onLocationChanged(LocationState locationState) {
    if (!_intendsOnline) return;

    switch (locationState) {
      case LocationStateServiceDisabled():
        AppLogger.w('Location services disabled while online — going offline');
        unawaited(
          _goOfflineBecause(
            AvailabilityBlockReason.locationServiceDisabled,
            'Location services were turned off. You are now offline.',
          ),
        );

      case LocationStatePermissionDenied():
        AppLogger.w('Location permission revoked while online — going offline');
        unawaited(
          _goOfflineBecause(
            AvailabilityBlockReason.locationPermissionDenied,
            'Location permission was revoked. You are now offline.',
          ),
        );

      case LocationStateTracking(:final position):
        _maybeSend(position);

      case LocationStateInitial():
      case LocationStateRequesting():
      case LocationStateAcquiring():
      case LocationStateError():
        break;
    }
  }

  Future<void> _goOfflineBecause(
    AvailabilityBlockReason reason,
    String message,
  ) async {
    _intendsOnline = false;
    _stopHeartbeat();
    unawaited(
      ref
          .read(locationNotifierProvider.notifier)
          .setForegroundNotification(enabled: false),
    );
    await _detachConsumer();
    state = AvailabilityState.blocked(reason: reason, message: message);
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(
      kLocationHeartbeat,
      (_) => _pushCurrentPosition(),
    );
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  void _pushCurrentPosition({bool force = false}) {
    final position = ref.read(locationNotifierProvider).positionOrNull;
    if (position == null) return;
    _maybeSend(position, force: force);
  }

  void _maybeSend(LatLng position, {bool force = false}) {
    final consumer = _consumer;
    if (consumer == null || !state.isOnline) return;

    final now = DateTime.now();
    if (!force && !_throttle.shouldSend(position, now)) return;

    consumer.sendLocation(position);
    _throttle.recordSent(position, now);
  }

  // ---------------------------------------------------------------------------

  void _teardown() {
    _stopHeartbeat();
    _eventSubscription?.cancel();
    _connectionSubscription?.cancel();
    final consumer = _consumer;
    _consumer = null;
    consumer?.disconnect();
    consumer?.dispose();
    _rideRequestController.close();
  }
}
