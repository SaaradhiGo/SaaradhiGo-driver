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
      rcDoc: json['rc_doc'] as String?,
      vehiclePic: json['vehicle_pic'] as String?,
      fuelType: json['fuel_type'] as String?,
      insuranceDoc: json['insurance_doc'] as String?,
      insuranceExpiry: json['insurance_expiry'] == null
          ? null
          : DateTime.parse(json['insurance_expiry'] as String),
      fitnessExpiry: json['fitness_expiry'] == null
          ? null
          : DateTime.parse(json['fitness_expiry'] as String),
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
      'rc_doc': instance.rcDoc,
      'vehicle_pic': instance.vehiclePic,
      'fuel_type': instance.fuelType,
      'insurance_doc': instance.insuranceDoc,
      'insurance_expiry': instance.insuranceExpiry?.toIso8601String(),
      'fitness_expiry': instance.fitnessExpiry?.toIso8601String(),
    };
