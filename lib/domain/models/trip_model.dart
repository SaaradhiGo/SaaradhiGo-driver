import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_model.freezed.dart';
part 'trip_model.g.dart';

enum TripStatus {
  @JsonValue('requested')
  requested,
  @JsonValue('accept')
  accept,
  @JsonValue('reached')
  reached,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

Object? _readId(Map json, String key) {
  return json['id'] ?? json['trip_id'];
}

@freezed
abstract class TripModel with _$TripModel {
  const factory TripModel({
    @JsonKey(readValue: _readId) required int id,
    @JsonKey(defaultValue: TripStatus.requested) required TripStatus status,
    @JsonKey(name: 'rider_id') int? riderId,
    @JsonKey(name: 'rider_name') String? riderName,
    @JsonKey(name: 'driver_id') int? driverId,
    @JsonKey(name: 'pickup_lat') required double pickupLat,
    @JsonKey(name: 'pickup_lng') required double pickupLng,
    @JsonKey(name: 'destination_lat') required double destinationLat,
    @JsonKey(name: 'destination_lng') required double destinationLng,
    @JsonKey(name: 'pickup_address') String? pickupAddress,
    @JsonKey(name: 'destination_address') String? destinationAddress,
    @JsonKey(name: 'estimated_fare') required String estimatedFare,
    String? otp,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'duration_min') double? durationMin,
  }) = _TripModel;

  factory TripModel.fromJson(Map<String, dynamic> json) =>
      _$TripModelFromJson(json);
}
