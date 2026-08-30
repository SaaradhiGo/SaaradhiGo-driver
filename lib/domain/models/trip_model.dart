import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_model.freezed.dart';
part 'trip_model.g.dart';

/// Canonical trip lifecycle states.
///
/// [JsonValue]s are the backend **model status codes** returned by REST
/// (`GET /ride/active/`, `status` derived from `status_id.status_code`), NOT the
/// action verbs the WebSocket `trip_status_update` broadcasts carry. The socket
/// verbs (`accept`/`start`/`complete`/`cancel`) are mapped to these codes by
/// [tripStatusFromWsAction] in the trip status consumer — never deserialised
/// through this enum.
enum TripStatus {
  @JsonValue('requested')
  requested,
  @JsonValue('accepted')
  accepted,
  @JsonValue('reached')
  reached,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

/// True once the trip has reached a terminal state and the socket can close.
extension TripStatusX on TripStatus {
  bool get isTerminal =>
      this == TripStatus.completed || this == TripStatus.cancelled;
  bool get isActive => !isTerminal;
}

Object? _readId(Map json, String key) => json['id'] ?? json['trip_id'];

// The dispatch (`ride_request`) socket payload uses `pickup_lng`/`destination_lng`;
// the REST trip serializers use `pickup_long`/`destination_long`. Accept either
// so a TripModel round-trips from both sources (docs/08_REALTIME.md vs
// servers/ride/serializers.py).
Object? _readPickupLng(Map json, String key) =>
    json['pickup_lng'] ?? json['pickup_long'];
Object? _readDestinationLng(Map json, String key) =>
    json['destination_lng'] ?? json['destination_long'];

// REST exposes distance/duration split into estimated_* and actual_* keys; the
// dispatch payload uses the flat distance_km/duration_min. Prefer the actual
// value when present (a completed trip), then estimated, then the flat key.
Object? _readDistanceKm(Map json, String key) =>
    json['distance_km'] ??
    json['actual_distance_km'] ??
    json['estimated_distance_km'];
Object? _readDurationMin(Map json, String key) =>
    json['duration_min'] ??
    json['actual_duration_min'] ??
    json['estimated_duration_min'];

// Fares arrive as strings over the socket but can be numeric over REST — coerce
// so a numeric fare never throws a type error during parsing.
Object? _readEstimatedFare(Map json, String key) =>
    json['estimated_fare']?.toString();
Object? _readFinalFare(Map json, String key) => json['final_fare']?.toString();

/// A single ride trip, parsed from either the `ride_request` dispatch payload,
/// a `trip_status_update` broadcast, or `GET /ride/active/`.
///
/// Coordinates are nullable because a partial recovery payload may omit them;
/// the UI falls back to the map's default centre when a fix is missing.
@freezed
abstract class TripModel with _$TripModel {
  const factory TripModel({
    @JsonKey(readValue: _readId) required int id,
    @JsonKey(defaultValue: TripStatus.requested) required TripStatus status,
    @JsonKey(name: 'rider_id') int? riderId,
    @JsonKey(name: 'rider_name') String? riderName,
    @JsonKey(name: 'driver_id') int? driverId,
    @JsonKey(name: 'driver_name') String? driverName,
    @JsonKey(name: 'pickup_lat') double? pickupLat,
    @JsonKey(readValue: _readPickupLng) double? pickupLng,
    @JsonKey(name: 'destination_lat') double? destinationLat,
    @JsonKey(readValue: _readDestinationLng) double? destinationLng,
    @JsonKey(name: 'pickup_address') String? pickupAddress,
    @JsonKey(name: 'destination_address') String? destinationAddress,
    @JsonKey(readValue: _readEstimatedFare) String? estimatedFare,
    @JsonKey(readValue: _readFinalFare) String? finalFare,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(name: 'vehicle_type') String? vehicleType,
    String? otp,
    @JsonKey(readValue: _readDistanceKm) double? distanceKm,
    @JsonKey(readValue: _readDurationMin) double? durationMin,
  }) = _TripModel;

  factory TripModel.fromJson(Map<String, dynamic> json) =>
      _$TripModelFromJson(json);
}
