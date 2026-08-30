import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  TripSessionState build() {
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
  }

  /// Crash recovery: rejoins an in-flight trip returned by `GET /ride/active/`.
  void resumeActiveTrip(TripModel trip) {
    if (trip.status.isTerminal) return;
    if (state.trip?.id == trip.id && !state.isTerminal) return;

    state = TripSessionState(trip: trip, status: trip.status, connecting: true);
    _pendingAccept = false;
    _attachConsumer(trip.id);
    _consumer!.connect();
    unawaited(LocalStorageService.setActiveTripId(trip.id.toString()));
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

      case TripStatusChanged(:final status):
        AppLogger.i('Trip ${_consumer?.tripId} → ${status.name}');
        final trip = state.trip?.copyWith(status: status);
        state = state.copyWith(
          status: status,
          trip: trip,
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
          // No further updates on a settled trip — release the socket but keep
          // the state so the summary/cancel UI can render.
          _detachConsumer();
          unawaited(LocalStorageService.clearActiveTripId());
        }

      case TripTakenEvent():
        AppLogger.i('Trip taken by another driver');
        _detachConsumer();
        unawaited(LocalStorageService.clearActiveTripId());
        state = state.copyWith(
          takenByOther: true,
          connecting: false,
          actionInProgress: false,
        );

      case TripStatusErrorEvent(:final message, :final isOtpError):
        AppLogger.w('Trip action rejected: $message');
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
    _detachConsumer();
  }
}
