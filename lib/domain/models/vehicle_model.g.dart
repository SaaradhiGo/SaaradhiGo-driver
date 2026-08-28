// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VehicleModel _$VehicleModelFromJson(Map<String, dynamic> json) =>
    _VehicleModel(
      id: (json['id'] as num).toInt(),
      vehicleNumber: json['vehicle_number'] as String,
      vehicleType: const VehicleTypeConverter().fromJson(json['vehicle_type']),
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      color: json['color'] as String?,
      year: (json['year'] as num?)?.toInt(),
      capacity: (json['capacity'] as num?)?.toInt(),
      status: json['status'] as String?,
    );

Map<String, dynamic> _$VehicleModelToJson(_VehicleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_number': instance.vehicleNumber,
      'vehicle_type': const VehicleTypeConverter().toJson(instance.vehicleType),
      'brand': instance.brand,
      'model': instance.model,
      'color': instance.color,
      'year': instance.year,
      'capacity': instance.capacity,
      'status': instance.status,
    };
