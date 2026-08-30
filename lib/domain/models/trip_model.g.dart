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
  driverName: json['driver_name'] as String?,
  pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
  pickupLng: (_readPickupLng(json, 'pickupLng') as num?)?.toDouble(),
  destinationLat: (json['destination_lat'] as num?)?.toDouble(),
  destinationLng: (_readDestinationLng(json, 'destinationLng') as num?)
      ?.toDouble(),
  pickupAddress: json['pickup_address'] as String?,
  destinationAddress: json['destination_address'] as String?,
  estimatedFare: _readEstimatedFare(json, 'estimatedFare') as String?,
  finalFare: _readFinalFare(json, 'finalFare') as String?,
  paymentMethod: json['payment_method'] as String?,
  vehicleType: json['vehicle_type'] as String?,
  otp: json['otp'] as String?,
  distanceKm: (_readDistanceKm(json, 'distanceKm') as num?)?.toDouble(),
  durationMin: (_readDurationMin(json, 'durationMin') as num?)?.toDouble(),
);

Map<String, dynamic> _$TripModelToJson(_TripModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$TripStatusEnumMap[instance.status]!,
      'rider_id': instance.riderId,
      'rider_name': instance.riderName,
      'driver_id': instance.driverId,
      'driver_name': instance.driverName,
      'pickup_lat': instance.pickupLat,
      'pickupLng': instance.pickupLng,
      'destination_lat': instance.destinationLat,
      'destinationLng': instance.destinationLng,
      'pickup_address': instance.pickupAddress,
      'destination_address': instance.destinationAddress,
      'estimatedFare': instance.estimatedFare,
      'finalFare': instance.finalFare,
      'payment_method': instance.paymentMethod,
      'vehicle_type': instance.vehicleType,
      'otp': instance.otp,
      'distanceKm': instance.distanceKm,
      'durationMin': instance.durationMin,
    };

const _$TripStatusEnumMap = {
  TripStatus.requested: 'requested',
  TripStatus.accepted: 'accepted',
  TripStatus.reached: 'reached',
  TripStatus.inProgress: 'in_progress',
  TripStatus.completed: 'completed',
  TripStatus.cancelled: 'cancelled',
};
