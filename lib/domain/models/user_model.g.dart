// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: (json['id'] as num).toInt(),
  phoneNumber: json['phone_number'] as String?,
  role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ?? UserRole.driver,
  fullName: json['full_name'] as String?,
  email: json['email'] as String?,
  avatar: json['avatar'] as String?,
  isUpdated: json['is_updated'] as bool? ?? false,
  fcmToken: json['fcm_token'] as String?,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone_number': instance.phoneNumber,
      'role': _$UserRoleEnumMap[instance.role]!,
      'full_name': instance.fullName,
      'email': instance.email,
      'avatar': instance.avatar,
      'is_updated': instance.isUpdated,
      'fcm_token': instance.fcmToken,
    };

const _$UserRoleEnumMap = {
  UserRole.driver: 'driver',
  UserRole.rider: 'rider',
  UserRole.admin: 'admin',
};
