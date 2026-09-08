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

double? _readDoubleVal(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

int? _readIntVal(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

Object? _readId(Map json, String key) {
  final val = json['id'] ?? json['trip_id'];
  return _readIntVal(val) ?? 0;
}

String _normalizeStatusCode(dynamic raw) {
  final s = raw?.toString().trim().toLowerCase() ?? '';
  switch (s) {
    case 'pending':
    case 'requested':
      return 'requested';
    case 'accept':
    case 'accepted':
    case 'driver_accepted':
      return 'accepted';
    case 'reached':
    case 'arrived':
    case 'driver_reached':
    case 'driver_arrived':
      return 'reached';
    case 'start':
    case 'started':
    case 'in_progress':
    case 'inprogress':
    case 'in-progress':
    case 'trip_started':
      return 'in_progress';
    case 'complete':
    case 'completed':
    case 'trip_completed':
    case 'finished':
      return 'completed';
    case 'cancel':
    case 'cancelled':
    case 'canceled':
    case 'trip_cancelled':
    case 'driver_cancelled':
    case 'rider_cancelled':
      return 'cancelled';
    default:
      return 'requested';
  }
}

Object? _readStatus(Map json, String key) {
  final raw = json['status'] ?? json['trip_status'];
  if (raw is Map) {
    return _normalizeStatusCode(
      raw['status_code'] ?? raw['code'] ?? raw['name'],
    );
  }
  if (raw != null) {
    return _normalizeStatusCode(raw);
  }
  if (json['status_id'] is Map) {
    return _normalizeStatusCode(json['status_id']['status_code']);
  }
  return 'requested';
}

Object? _readRiderId(Map json, String key) {
  final val = json['rider_id'] ?? json['rider'];
  if (val is Map) return _readIntVal(val['id']);
  return _readIntVal(val);
}

Object? _readDriverId(Map json, String key) {
  final val = json['driver_id'] ?? json['driver'];
  if (val is Map) return _readIntVal(val['id']);
  return _readIntVal(val);
}

Object? _readPickupLat(Map json, String key) =>
    _readDoubleVal(json['pickup_lat']);

// The dispatch (`ride_request`) socket payload uses `pickup_lng`/`destination_lng`;
// the REST trip serializers use `pickup_long`/`destination_long`. Accept either
// and coerce Decimal strings.
Object? _readPickupLng(Map json, String key) =>
    _readDoubleVal(json['pickup_lng'] ?? json['pickup_long']);

Object? _readDestinationLat(Map json, String key) =>
    _readDoubleVal(json['destination_lat']);

Object? _readDestinationLng(Map json, String key) =>
    _readDoubleVal(json['destination_lng'] ?? json['destination_long']);

// REST exposes distance/duration split into estimated_* and actual_* keys; the
// dispatch payload uses the flat distance_km/duration_min. Prefer the actual
// value when present, then estimated, then the flat key.
Object? _readDistanceKm(Map json, String key) => _readDoubleVal(
  json['distance_km'] ??
      json['actual_distance_km'] ??
      json['estimated_distance_km'],
);

Object? _readDurationMin(Map json, String key) => _readDoubleVal(
  json['duration_min'] ??
      json['actual_duration_min'] ??
      json['estimated_duration_min'],
);

// Fares arrive as strings over the socket but can be numeric over REST — coerce
// so a numeric fare never throws a type error during parsing.
Object? _readEstimatedFare(Map json, String key) =>
    json['estimated_fare']?.toString();
Object? _readFinalFare(Map json, String key) => json['final_fare']?.toString();

Object? _readRiderName(Map json, String key) {
  final val = json['rider_name'] ?? json['user'];
  if (val is String && val.trim().isNotEmpty) return val.trim();
  if (val is Map) {
    final first = val['first_name'] ?? val['name'] ?? '';
    final last = val['last_name'] ?? '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    return val['username']?.toString() ?? 'Rider';
  }
  if (val != null) return val.toString();
  return 'Rider';
}

Object? _readCreatedAt(Map json, String key) =>
    json['created_at']?.toString() ?? json['requested_at']?.toString();

Object? _readRiderRating(Map json, String key) {
  final val = json['rider_rating'] ?? json['rating'] ?? json['user_rating'];
  return _readDoubleVal(val);
}

Object? _readDriverRating(Map json, String key) {
  final val = json['driver_rating'] ?? json['rating_given'];
  return _readDoubleVal(val);
}

Object? _readCancellationReason(Map json, String key) =>
    json['cancellation_reason'] ?? json['reason'] ?? json['cancel_reason'];

Object? _readSurgeMultiplier(Map json, String key) =>
    json['surge_multiplier']?.toString();

Object? _readFareBreakdown(Map json, String key) {
  final val = json['fare_breakdown'];
  if (val is Map) {
    return Map<String, dynamic>.from(val);
  }
  return null;
}

/// A single ride trip, parsed from either the `ride_request` dispatch payload,
/// a `trip_status_update` broadcast, or `GET /ride/active/`.
///
/// Coordinates are nullable because a partial recovery payload may omit them;
/// the UI falls back to the map's default centre when a fix is missing.
@freezed
abstract class TripModel with _$TripModel {
  const factory TripModel({
    @JsonKey(readValue: _readId) required int id,
    @JsonKey(defaultValue: TripStatus.requested, readValue: _readStatus)
    required TripStatus status,
    @JsonKey(name: 'rider_id', readValue: _readRiderId) int? riderId,
    @JsonKey(readValue: _readRiderName) String? riderName,
    @JsonKey(name: 'driver_id', readValue: _readDriverId) int? driverId,
    @JsonKey(name: 'driver_name') String? driverName,
    @JsonKey(name: 'pickup_lat', readValue: _readPickupLat) double? pickupLat,
    @JsonKey(readValue: _readPickupLng) double? pickupLng,
    @JsonKey(name: 'destination_lat', readValue: _readDestinationLat)
    double? destinationLat,
    @JsonKey(readValue: _readDestinationLng) double? destinationLng,
    @JsonKey(name: 'pickup_address') String? pickupAddress,
    @JsonKey(name: 'destination_address') String? destinationAddress,
    @JsonKey(readValue: _readEstimatedFare) String? estimatedFare,
    @JsonKey(readValue: _readFinalFare) String? finalFare,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(name: 'payment_status') String? paymentStatus,
    @JsonKey(name: 'vehicle_type') String? vehicleType,
    String? otp,
    @JsonKey(readValue: _readDistanceKm) double? distanceKm,
    @JsonKey(readValue: _readDurationMin) double? durationMin,
    @JsonKey(readValue: _readCreatedAt) String? createdAt,
    @JsonKey(readValue: _readRiderRating) double? riderRating,
    @JsonKey(readValue: _readDriverRating) double? driverRating,
    @JsonKey(name: 'fare_breakdown', readValue: _readFareBreakdown)
    Map<String, dynamic>? fareBreakdown,
    @JsonKey(readValue: _readCancellationReason) String? cancellationReason,
    @JsonKey(name: 'cancelled_at') String? cancelledAt,
    @JsonKey(readValue: _readSurgeMultiplier) String? surgeMultiplier,
  }) = _TripModel;

  factory TripModel.fromJson(Map<String, dynamic> json) =>
      _$TripModelFromJson(json);
}
