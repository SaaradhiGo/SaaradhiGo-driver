import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../dashboard/data/data_sources/driver_location_consumer.dart';
import '../../data/data_sources/trip_status_consumer.dart';
import 'trip_providers.dart';

/// Owns the per-trip socket and drives the ride lifecycle state machine.
///
/// Lifecycle (WS action verb → resulting [TripStatus]):
/// accept→accepted, reached→reached, start→in_progress, complete→completed,
/// cancel→cancelled. On success the backend does NOT reply directly — it
/// group-sends a `trip_status_update`; on failure it sends `{type:error}`.
class TripSessionNotifier extends Notifier<TripSessionState> {
  TripStatusConsumer? _consumer;
  StreamSubscription<TripStatusEvent>? _eventSub;
  StreamSubscription<WebSocketState>? _connSub;

  /// Set between opening the socket and receiving `connection_established`, so
  /// the queued action (accept) is sent exactly once the channel is ready.
  bool _pendingAccept = false;

  /// Bounds the wait between accepting an offer and the backend confirming it.
  ///
  /// THE FAILURE THIS CLOSES (trip #79 on QA)
  /// The driver accepted an offer the backend had ALREADY cancelled
  /// (`no_driver_accepted`). The accept was refused, no `trip_status_update`
  /// ever arrived, and the app sat on "Preparing ride…" forever -- while
  /// holding the trip screen, so it showed no further offers and the driver
  /// was invisible to dispatch while still appearing online. There was no
  /// timeout anywhere on this path.
  Timer? _acceptWatchdog;

  /// Long enough for a slow network to deliver the update, short enough that
  /// a driver is not stranded on a dead screen.
  static const Duration _acceptTimeout = Duration(seconds: 15);

  @override
  TripSessionState build() {
    // Pause/resume the trip socket's reconnect budget with platform
    // connectivity so airplane mode never exhausts the backoff while a trip is
    // in flight (docs/14_ERROR_HANDLING.md:18).
    ref.listen<bool>(isOnlineNetworkProvider, (previous, next) {
      if (previous == next) return;
      _consumer?.updateNetworkStatus(next);
    });
    ref.onDispose(_teardown);
    return const TripSessionState();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Accepts a socket-dispatched ride: opens the trip channel and, once
  /// connected, sends `{"action":"accept"}`.
  Future<void> acceptFromRequest(DriverLocationRideRequest request) async {
    final tripId = request.tripId;
    if (tripId == null) {
      state = state.copyWith(
        errorMessage: 'Ride request is missing a trip id.',
      );
      return;
    }
    if (state.trip != null && !state.isTerminal) return;

    final initial = _tripFromPayload(request.payload, tripId);
    state = TripSessionState(
      trip: initial,
      status: TripStatus.requested,
      connecting: true,
    );

    _pendingAccept = true;
    _attachConsumer(tripId);
    _consumer!.connect();
    _armAcceptWatchdog();
  }

  /// Crash recovery: rejoins an in-flight trip returned by `GET /ride/active/`.
  void resumeActiveTrip(TripModel trip) {
    if (trip.status.isTerminal) return;
    if (state.trip?.id == trip.id && !state.isTerminal) return;

    // If an assigned active trip arrives with 'requested', normalize to 'accepted'
    // so the driver enters the active lifecycle (heading to pickup) immediately.
    final effectiveStatus = (trip.status == TripStatus.requested)
        ? TripStatus.accepted
        : trip.status;
    final effectiveTrip = (effectiveStatus != trip.status)
        ? trip.copyWith(status: effectiveStatus)
        : trip;

    AppLogger.i(
      'Resuming active trip ${trip.id} in state: ${effectiveStatus.name}',
    );
    state = TripSessionState(
      trip: effectiveTrip,
      status: effectiveStatus,
      connecting: true,
    );
    _pendingAccept = false;
    _attachConsumer(trip.id);
    _consumer!.connect();
    unawaited(LocalStorageService.setActiveTripId(trip.id.toString()));
  }

  /// Checks active trip on app resume (e.g. returning from Google Maps).
  /// If the trip was cancelled while away or no longer active on the backend,
  /// transitions to cancelled state and alerts the driver.
  Future<void> checkActiveTripOnResume() async {
    if (!state.isActive) return;

    try {
      final trip = await ref.read(tripRepositoryProvider).getActiveTrip();
      if (trip == null || trip.status.isTerminal) {
        AppLogger.w(
          'Active trip check on resume: trip ended or cancelled on backend (id: ${state.trip?.id})',
        );
        HapticFeedback.heavyImpact();
        state = state.copyWith(
          status: TripStatus.cancelled,
          trip: state.trip?.copyWith(status: TripStatus.cancelled),
          cancellationReason: trip?.status == TripStatus.cancelled
              ? 'Ride was cancelled by the passenger.'
              : 'Trip is no longer active.',
          connecting: false,
          actionInProgress: false,
        );
        _detachConsumer();
        unawaited(LocalStorageService.clearActiveTripId());
      }
    } catch (e, st) {
      AppLogger.w('Failed checking active trip on resume: $e\n$st');
    }
  }

  /// Driver arrived at pickup: `{"action":"reached"}`.
  void markReached() => _sendAction('reached');

  /// Start the ride with the rider's 6-digit OTP: `{"action":"start","otp":…}`.
  void startRide(String otp) {
    state = state.copyWith(otpError: null);
    _sendAction('start', otp: otp);
  }

  /// Complete the ride: `{"action":"complete"}`.
  void completeRide() => _sendAction('complete');

  /// Cancel the ride over the socket: `{"action":"cancel","reason":…}`.
  void cancelTrip({String? reason}) => _sendAction('cancel', reason: reason);

  /// Confirm cash collected (cash trips): `{"action":"confirm_cash"}`.
  void confirmCash() => _sendAction('confirm_cash');

  /// Clears a settled/aborted session so the driver returns to idle.
  void clear() {
    _cancelAcceptWatchdog();
    _teardown();
    _pendingAccept = false;
    state = const TripSessionState();
    unawaited(LocalStorageService.clearActiveTripId());
  }

  /// Dismisses a non-fatal banner error without tearing down the session.
  void acknowledgeError() =>
      state = state.copyWith(errorMessage: null, otpError: null);

  // ---------------------------------------------------------------------------
  // Socket wiring
  // ---------------------------------------------------------------------------

  void _attachConsumer(int tripId) {
    _detachConsumer();
    final consumer = ref.read(tripStatusConsumerFactoryProvider)(tripId);
    _consumer = consumer;
    _eventSub = consumer.events.listen(_onEvent);
    _connSub = consumer.connectionState.listen(_onConnectionState);
  }

  void _detachConsumer() {
    _eventSub?.cancel();
    _eventSub = null;
    _connSub?.cancel();
    _connSub = null;
    final consumer = _consumer;
    _consumer = null;
    if (consumer != null) {
      consumer.disconnect();
      unawaited(consumer.dispose());
    }
  }

  void _sendAction(String action, {String? otp, String? reason}) {
    final consumer = _consumer;
    if (consumer == null) {
      state = state.copyWith(
        errorMessage: 'Not connected to the trip. Please retry.',
      );
      return;
    }
    state = state.copyWith(actionInProgress: true, errorMessage: null);
    consumer.sendAction(action, otp: otp, reason: reason);
  }

  void _onEvent(TripStatusEvent event) {
    switch (event) {
      case TripConnectionEstablished():
        state = state.copyWith(connecting: false);
        if (_pendingAccept) {
          _pendingAccept = false;
          _sendAction('accept');
        }

      case TripStatusChanged(:final status, :final message):
        AppLogger.i('Trip ${_consumer?.tripId} → ${status.name}');
        // The backend has spoken about this trip, so the acceptance is no
        // longer in doubt and the watchdog must not fire later and tear down
        // a ride that is genuinely ours.
        _cancelAcceptWatchdog();
        final trip = state.trip?.copyWith(status: status);
        if (status == TripStatus.cancelled) {
          HapticFeedback.heavyImpact();
        }
        state = state.copyWith(
          status: status,
          trip: trip,
          cancellationReason: (status == TripStatus.cancelled)
              ? (message ?? state.cancellationReason)
              : state.cancellationReason,
          connecting: false,
          actionInProgress: false,
          otpError: null,
        );
        if (status == TripStatus.accepted) {
          final id = _consumer?.tripId;
          if (id != null) {
            unawaited(LocalStorageService.setActiveTripId(id.toString()));
          }
        }
        if (status.isTerminal) {
          // A completed cash trip still needs the driver to confirm collection,
          // which the backend accepts only over a live socket while the trip is
          // `completed`. Keep the channel (and the persisted id, for recovery)
          // open in that case; release it for every other terminal outcome.
          if (state.needsCashCollection) {
            AppLogger.i('Holding socket open for cash confirmation');
          } else {
            _detachConsumer();
            unawaited(LocalStorageService.clearActiveTripId());
          }
        }

      case TripCashConfirmed():
        AppLogger.i('Cash collection confirmed for trip ${_consumer?.tripId}');
        state = state.copyWith(cashConfirmed: true, actionInProgress: false);
        _detachConsumer();
        unawaited(LocalStorageService.clearActiveTripId());

      case TripTakenEvent():
        AppLogger.i('Trip taken by another driver');
        _cancelAcceptWatchdog();
        _detachConsumer();
        unawaited(LocalStorageService.clearActiveTripId());
        state = state.copyWith(
          takenByOther: true,
          connecting: false,
          actionInProgress: false,
        );

      case TripStatusErrorEvent(:final message, :final isOtpError):
        AppLogger.w('Trip action rejected: $message');
        // The backend refused something. If we were still waiting for an
        // accept to be confirmed, that refusal IS the answer -- reconcile now
        // rather than sitting on the screen until the watchdog fires.
        if (_acceptWatchdog != null && state.status != TripStatus.accepted) {
          _cancelAcceptWatchdog();
          unawaited(_reconcileAfterAcceptTimeout());
          return;
        }
        if (isOtpError) {
          state = state.copyWith(actionInProgress: false, otpError: message);
        } else {
          state = state.copyWith(
            actionInProgress: false,
            errorMessage: message,
          );
        }

      case TripStatusUnknownEvent(:final type):
        AppLogger.w('Unhandled trip event type: $type');
    }
  }

  void _onConnectionState(WebSocketState wsState) {
    if (state.isTerminal) return;
    switch (wsState) {
      case WebSocketState.connecting:
      case WebSocketState.connected:
      case WebSocketState.disconnected:
        break;
      case WebSocketState.error:
        // Backoff exhausted. Surface it but keep the trip data so the driver
        // can retry via /ride/active/ recovery rather than losing the fare.
        state = state.copyWith(
          socketError: true,
          connecting: false,
          actionInProgress: false,
          errorMessage: 'Lost connection to the trip. Reopen to reconnect.',
        );
    }
  }

  TripModel _tripFromPayload(Map<String, dynamic> payload, int tripId) {
    final json = <String, dynamic>{...payload, 'trip_id': tripId};
    try {
      return TripModel.fromJson(json);
    } catch (error, stackTrace) {
      AppLogger.e('Failed to parse ride_request payload', error, stackTrace);
      return TripModel(id: tripId, status: TripStatus.requested);
    }
  }

  void _teardown() {
    _cancelAcceptWatchdog();
    _detachConsumer();
  }

  // ---------------------------------------------------------------------------
  // Acceptance watchdog
  // ---------------------------------------------------------------------------

  void _armAcceptWatchdog() {
    _cancelAcceptWatchdog();
    _acceptWatchdog = Timer(_acceptTimeout, () {
      unawaited(_reconcileAfterAcceptTimeout());
    });
  }

  void _cancelAcceptWatchdog() {
    _acceptWatchdog?.cancel();
    _acceptWatchdog = null;
  }

  /// The accept was not confirmed in time. Ask the BACKEND what is true.
  ///
  /// The app's own state is the thing in doubt here, so it is not consulted:
  /// `/ride/active/` is authoritative about whether this driver is on a trip.
  ///
  ///   * a live trip for us  -> adopt it and carry on (the update was lost,
  ///                            not the trip)
  ///   * anything else       -> the offer is gone. Release the screen so the
  ///                            driver returns to the duty screen and dispatch
  ///                            can offer them the next ride.
  Future<void> _reconcileAfterAcceptTimeout() async {
    _acceptWatchdog = null;

    // Already settled while the timer was pending.
    if (state.isTerminal || state.status == TripStatus.accepted) return;
    if (state.trip == null) return;

    final pendingTripId = state.trip?.id;
    AppLogger.w(
      'Accept not confirmed in time for trip $pendingTripId; '
      'reconciling against the backend',
    );

    TripModel? active;
    try {
      active = await ref.read(tripRepositoryProvider).getActiveTrip();
    } catch (error, stackTrace) {
      // Could not ask. Do NOT strand the driver on the trip screen on the
      // strength of a failed request -- release it and let /ride/active/
      // recovery re-adopt the trip if there really is one.
      AppLogger.w('Reconcile failed', error, stackTrace);
      _releaseUnconfirmedRide(
        'We could not confirm that ride. You are back online.',
      );
      return;
    }

    if (active != null && !active.status.isTerminal) {
      AppLogger.i('Reconcile: backend has trip ${active.id} active; adopting');
      _cancelAcceptWatchdog();
      _pendingAccept = false;

      // Adopt the backend's view directly rather than calling
      // `resumeActiveTrip`: that method early-returns when the session
      // already holds this trip id, which is exactly the situation here --
      // so routing through it left the driver on "Preparing ride…" with a
      // trip the backend had confirmed. Caught by the test below.
      final adopted = (active.status == TripStatus.requested)
          ? active.copyWith(status: TripStatus.accepted)
          : active;
      state = state.copyWith(
        trip: adopted,
        status: adopted.status,
        connecting: false,
        actionInProgress: false,
        errorMessage: null,
      );
      unawaited(LocalStorageService.setActiveTripId(adopted.id.toString()));

      // Re-attach only if we lost the channel; the existing one is already
      // subscribed to this trip.
      if (_consumer == null) {
        _attachConsumer(adopted.id);
        _consumer!.connect();
      }
      return;
    }

    _releaseUnconfirmedRide(
      'That ride is no longer available. You are back online.',
    );
  }

  /// Drops an unconfirmed ride and returns the driver to the duty screen.
  void _releaseUnconfirmedRide(String message) {
    _cancelAcceptWatchdog();
    _pendingAccept = false;
    _detachConsumer();
    unawaited(LocalStorageService.clearActiveTripId());
    state = TripSessionState(offerLost: true, errorMessage: message);
  }
}
