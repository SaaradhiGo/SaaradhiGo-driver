import 'package:freezed_annotation/freezed_annotation.dart';

part 'availability_state.freezed.dart';

/// Why the driver cannot currently go online.
enum AvailabilityBlockReason {
  profileLoading,
  profileUnavailable,
  notApproved,
  noActiveVehicle,
  locationServiceDisabled,
  locationPermissionDenied,
  awaitingGpsFix,
  noNetwork,
}

/// Driver availability, derived entirely from the driver location WebSocket
/// lifecycle.
///
/// There is no REST availability endpoint. `docs/19_MISSING_REQUIREMENTS.md`
/// Conflict 1: online status is the presence of an active connection to
/// `DriverLocationConsumer`. The `/driver/availability`, `/driver/online` and
/// `/driver/offline` routes referenced in
/// `docs/22_STATE_MANAGEMENT_SPECIFICATION.md` exist in no backend contract and
/// are deliberately not called.
@freezed
sealed class AvailabilityState with _$AvailabilityState {
  /// Not connected and not trying to be.
  const factory AvailabilityState.offline() = AvailabilityStateOffline;

  /// Socket opening; waiting for `connection_established`.
  const factory AvailabilityState.goingOnline() = AvailabilityStateGoingOnline;

  /// `connection_established` received — the backend has marked us online.
  const factory AvailabilityState.online({required DateTime since}) =
      AvailabilityStateOnline;

  /// Socket dropped while the driver still intends to be online; backoff is
  /// running. docs/14_ERROR_HANDLING.md:18 requires a "Reconnecting…" indicator.
  const factory AvailabilityState.reconnecting() =
      AvailabilityStateReconnecting;

  /// Closing the socket.
  const factory AvailabilityState.goingOffline() =
      AvailabilityStateGoingOffline;

  /// A pre-flight guard refused the transition.
  const factory AvailabilityState.blocked({
    required AvailabilityBlockReason reason,
    required String message,
  }) = AvailabilityStateBlocked;

  /// Reconnection exhausted or the socket failed unrecoverably.
  const factory AvailabilityState.error(String message) =
      AvailabilityStateError;
}

extension AvailabilityStateX on AvailabilityState {
  /// True only when the backend has confirmed us online.
  bool get isOnline => this is AvailabilityStateOnline;

  /// True while the driver intends to be online, including reconnection.
  bool get isEngaged => switch (this) {
    AvailabilityStateGoingOnline() ||
    AvailabilityStateOnline() ||
    AvailabilityStateReconnecting() => true,
    _ => false,
  };

  /// True while a transition is in flight — the toggle should show progress.
  bool get isTransitioning => switch (this) {
    AvailabilityStateGoingOnline() ||
    AvailabilityStateGoingOffline() ||
    AvailabilityStateReconnecting() => true,
    _ => false,
  };

  /// Message to surface, if any.
  String? get messageOrNull => switch (this) {
    AvailabilityStateBlocked(:final message) => message,
    AvailabilityStateError(:final message) => message,
    _ => null,
  };
}
