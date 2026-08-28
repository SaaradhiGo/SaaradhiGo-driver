// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripModel _$TripModelFromJson(Map<String, dynamic> json) => _TripModel(
  id: (_readId(json, 'id') as num).toInt(),
  status:
      $enumDecodeNullable(_$TripStatusEnumMap, json['status']) ??
      TripStatus.requested,
  riderId: (json['rider_id'] as num?)?.toInt(),
  riderName: json['rider_name'] as String?,
  driverId: (json['driver_id'] as num?)?.toInt(),
  pickupLat: (json['pickup_lat'] as num).toDouble(),
  pickupLng: (json['pickup_lng'] as num).toDouble(),
  destinationLat: (json['destination_lat'] as num).toDouble(),
  destinationLng: (json['destination_lng'] as num).toDouble(),
  pickupAddress: json['pickup_address'] as String?,
  destinationAddress: json['destination_address'] as String?,
  estimatedFare: json['estimated_fare'] as String,
  otp: json['otp'] as String?,
  distanceKm: (json['distance_km'] as num?)?.toDouble(),
  durationMin: (json['duration_min'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TripModelToJson(_TripModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$TripStatusEnumMap[instance.status]!,
      'rider_id': instance.riderId,
      'rider_name': instance.riderName,
      'driver_id': instance.driverId,
      'pickup_lat': instance.pickupLat,
      'pickup_lng': instance.pickupLng,
      'destination_lat': instance.destinationLat,
      'destination_lng': instance.destinationLng,
      'pickup_address': instance.pickupAddress,
      'destination_address': instance.destinationAddress,
      'estimated_fare': instance.estimatedFare,
      'otp': instance.otp,
      'distance_km': instance.distanceKm,
      'duration_min': instance.durationMin,
    };

const _$TripStatusEnumMap = {
  TripStatus.requested: 'requested',
  TripStatus.accept: 'accept',
  TripStatus.reached: 'reached',
  TripStatus.inProgress: 'in_progress',
  TripStatus.completed: 'completed',
  TripStatus.cancelled: 'cancelled',
};
