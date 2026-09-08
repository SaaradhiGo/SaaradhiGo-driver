import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/trip_model.dart';

part 'trip_session_state.freezed.dart';

/// Live state of the single active ride session.
///
/// There is at most one active trip per driver, so this is a flat snapshot
/// rather than a union: [status] is the authoritative lifecycle state (driven by
/// the socket), [trip] holds the accumulated trip data, and the boolean flags
/// track the transient transport/action conditions the UI must reflect.
@freezed
abstract class TripSessionState with _$TripSessionState {
  const TripSessionState._();

  const factory TripSessionState({
    TripModel? trip,
    TripStatus? status,

    /// Socket opening / accept in flight, before `connection_established`.
    @Default(false) bool connecting,

    /// A driver action was sent and we are awaiting its broadcast or error.
    @Default(false) bool actionInProgress,

    /// OTP-specific rejection, surfaced inline on the OTP field.
    String? otpError,

    /// Any other non-fatal error message to show as a banner/snackbar.
    String? errorMessage,

    /// This offer was won by another driver (`trip_taken`).
    @Default(false) bool takenByOther,

    /// The transport exhausted its reconnect budget.
    @Default(false) bool socketError,

    /// A cash trip's `confirm_cash` has been acknowledged by the backend.
    @Default(false) bool cashConfirmed,
  }) = _TripSessionState;

  /// No trip is in flight.
  bool get isIdle => trip == null && status == null && !connecting;

  /// A driver-blocking async operation is running.
  bool get isBusy => connecting || actionInProgress;

  /// The trip has settled into a terminal state.
  bool get isTerminal => status?.isTerminal ?? false;

  /// True when an active, non-terminal trip is underway.
  bool get isActive => trip != null && status != null && !isTerminal;

  /// A completed cash trip whose collection has not yet been confirmed. The
  /// driver must confirm before leaving the summary (and the socket is held
  /// open for it — the backend requires `completed` + a live channel).
  bool get needsCashCollection =>
      status == TripStatus.completed &&
      trip?.paymentMethod == 'cash' &&
      !cashConfirmed;
}
