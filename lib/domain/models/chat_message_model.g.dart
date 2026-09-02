// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessageModel _$ChatMessageModelFromJson(Map<String, dynamic> json) =>
    _ChatMessageModel(
      id: json['id'] == null ? 0 : intFromJson(json['id']),
      senderRole: json['sender_role'] as String?,
      body: json['body'] as String?,
      createdAt: json['created_at'] as String?,
      isSystem: json['is_system'] == null
          ? false
          : boolFromJson(json['is_system']),
    );

Map<String, dynamic> _$ChatMessageModelToJson(_ChatMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender_role': instance.senderRole,
      'body': instance.body,
      'created_at': instance.createdAt,
      'is_system': instance.isSystem,
    };
