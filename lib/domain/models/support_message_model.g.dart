// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SupportMessageModel _$SupportMessageModelFromJson(Map<String, dynamic> json) =>
    _SupportMessageModel(
      id: json['id'] == null ? 0 : intFromJson(json['id']),
      senderRole: _readSenderRole(json, 'senderRole') as String?,
      body: json['body'] as String?,
      createdAt: json['created_at'] as String?,
      isSystem: json['is_system'] == null
          ? false
          : boolFromJson(json['is_system']),
    );

Map<String, dynamic> _$SupportMessageModelToJson(
  _SupportMessageModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'senderRole': instance.senderRole,
  'body': instance.body,
  'created_at': instance.createdAt,
  'is_system': instance.isSystem,
};
