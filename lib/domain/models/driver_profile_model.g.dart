// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DriverProfileModel _$DriverProfileModelFromJson(
  Map<String, dynamic> json,
) => _DriverProfileModel(
  id: (json['id'] as num?)?.toInt() ?? 0,
  user: const UserOrIdConverter().fromJson(json['user']),
  status:
      $enumDecodeNullable(
        _$DriverStatusEnumMap,
        json['status'],
        unknownValue: DriverStatus.offline,
      ) ??
      DriverStatus.offline,
  approved: json['approved'] == null
      ? false
      : const SafeBoolConverter().fromJson(json['approved']),
  dispatchEligible: json['dispatch_eligible'] == null
      ? false
      : const SafeBoolConverter().fromJson(json['dispatch_eligible']),
  kycStatus: json['kyc_status'] as String?,
  licenseDoc: json['license_doc'] as String?,
  licenseDocBack: json['license_doc_back'] as String?,
  licenseExpiry: const SafeDateTimeConverter().fromJson(json['license_expiry']),
  activeVehicle: (json['active_vehicle'] as num?)?.toInt(),
  activeVehicleDetails: json['active_vehicle_details'] as Map<String, dynamic>?,
  totalTrips: (json['total_trips'] as num?)?.toInt(),
  ratings: const StringDoubleConverter().fromJson(json['ratings']),
);

Map<String, dynamic> _$DriverProfileModelToJson(_DriverProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': const UserOrIdConverter().toJson(instance.user),
      'status': _$DriverStatusEnumMap[instance.status]!,
      'approved': const SafeBoolConverter().toJson(instance.approved),
      'dispatch_eligible': const SafeBoolConverter().toJson(
        instance.dispatchEligible,
      ),
      'kyc_status': instance.kycStatus,
      'license_doc': instance.licenseDoc,
      'license_doc_back': instance.licenseDocBack,
      'license_expiry': const SafeDateTimeConverter().toJson(
        instance.licenseExpiry,
      ),
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
