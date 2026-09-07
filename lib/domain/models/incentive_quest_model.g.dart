// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incentive_quest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IncentiveQuestModel _$IncentiveQuestModelFromJson(Map<String, dynamic> json) =>
    _IncentiveQuestModel(
      id: intFromJson(json['id']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetTrips: json['target_trips'] == null
          ? 1
          : intFromJson(json['target_trips']),
      progressTrips: json['progress_trips'] == null
          ? 0
          : intFromJson(json['progress_trips']),
      rewardAmount: json['reward_amount'] == null
          ? '0.00'
          : moneyFromJson(json['reward_amount']),
      isCompleted: json['is_completed'] == null
          ? false
          : boolFromJson(json['is_completed']),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      type: json['type'] as String?,
    );

Map<String, dynamic> _$IncentiveQuestModelToJson(
  _IncentiveQuestModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'target_trips': instance.targetTrips,
  'progress_trips': instance.progressTrips,
  'reward_amount': instance.rewardAmount,
  'is_completed': instance.isCompleted,
  'expires_at': instance.expiresAt?.toIso8601String(),
  'type': instance.type,
};
