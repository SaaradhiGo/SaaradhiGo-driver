import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'location_state.freezed.dart';

/// UI-facing location state. Not a DTO — never serialised, so no
/// `json_serializable` here.
@freezed
sealed class LocationState with _$LocationState {
  /// Nothing attempted yet.
  const factory LocationState.initial() = LocationStateInitial;

  /// Permission / service pre-flight in progress.
  const factory LocationState.requesting() = LocationStateRequesting;

  /// Device location services are switched off. Blocks going online.
  const factory LocationState.serviceDisabled() = LocationStateServiceDisabled;

  /// Permission refused. [permanent] means only App Settings can fix it.
  const factory LocationState.permissionDenied({required bool permanent}) =
      LocationStatePermissionDenied;

  /// Permission granted, waiting on the first fix.
  const factory LocationState.acquiring() = LocationStateAcquiring;

  /// Streaming. [weakSignal] retains the last valid fix while flagging drift,
  /// per docs/10_LOCATION.md §4.
  const factory LocationState.tracking({
    required LatLng position,
    required DateTime timestamp,
    double? heading,
    double? accuracy,
    @Default(false) bool weakSignal,
    @Default(false) bool hasBackgroundAccess,
  }) = LocationStateTracking;

  /// Stream or platform failure.
  const factory LocationState.error(String message) = LocationStateError;
}

extension LocationStateX on LocationState {
  /// Last known coordinate, if any fix has ever arrived.
  LatLng? get positionOrNull => switch (this) {
    LocationStateTracking(:final position) => position,
    _ => null,
  };

  bool get isTracking => this is LocationStateTracking;

  /// True when the driver cannot go online because of location problems.
  bool get blocksGoingOnline => switch (this) {
    LocationStateTracking() => false,
    _ => true,
  };
}
