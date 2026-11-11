// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VehicleRequestDto _$VehicleRequestDtoFromJson(Map<String, dynamic> json) =>
    _VehicleRequestDto(
      registrationNumber: json['registration_number'] as String,
      vehicleType: json['vehicle_type'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      color: json['color'] as String,
      rcDocKey: json['rc_doc'] as String?,
    );

Map<String, dynamic> _$VehicleRequestDtoToJson(_VehicleRequestDto instance) =>
    <String, dynamic>{
      'registration_number': instance.registrationNumber,
      'vehicle_type': instance.vehicleType,
      'make': instance.make,
      'model': instance.model,
      'year': instance.year,
      'color': instance.color,
      'rc_doc': instance.rcDocKey,
    };
