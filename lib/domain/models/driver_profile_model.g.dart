// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DriverProfileModel _$DriverProfileModelFromJson(Map<String, dynamic> json) =>
    _DriverProfileModel(
      id: (json['id'] as num).toInt(),
      user: json['user'] == null
          ? null
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
      status: $enumDecode(_$DriverStatusEnumMap, json['status']),
      approved: json['approved'] as bool,
      kycStatus: json['kyc_status'] as String?,
      licenseDoc: json['license_doc'] as String?,
      licenseExpiry: json['license_expiry'] == null
          ? null
          : DateTime.parse(json['license_expiry'] as String),
      activeVehicle: (json['active_vehicle'] as num?)?.toInt(),
      activeVehicleDetails:
          json['active_vehicle_details'] as Map<String, dynamic>?,
      totalTrips: (json['total_trips'] as num?)?.toInt(),
      ratings: const StringDoubleConverter().fromJson(json['ratings']),
    );

Map<String, dynamic> _$DriverProfileModelToJson(_DriverProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'status': _$DriverStatusEnumMap[instance.status]!,
      'approved': instance.approved,
      'kyc_status': instance.kycStatus,
      'license_doc': instance.licenseDoc,
      'license_expiry': instance.licenseExpiry?.toIso8601String(),
      'active_vehicle': instance.activeVehicle,
      'active_vehicle_details': instance.activeVehicleDetails,
      'total_trips': instance.totalTrips,
      'ratings': const StringDoubleConverter().toJson(instance.ratings),
    };

const _$DriverStatusEnumMap = {
  DriverStatus.online: 'online',
  DriverStatus.offline: 'offline',
  DriverStatus.off: 'off',
};
