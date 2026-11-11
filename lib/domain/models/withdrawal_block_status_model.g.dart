// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_block_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WithdrawalBlockStatusModel _$WithdrawalBlockStatusModelFromJson(
  Map<String, dynamic> json,
) => _WithdrawalBlockStatusModel(
  blocked: json['blocked'] == null ? false : boolFromJson(json['blocked']),
  lastWithdrawalAt: json['last_withdrawal_at'] as String?,
  blockRemainingSeconds: nullableIntFromJson(json['block_remaining_seconds']),
);

Map<String, dynamic> _$WithdrawalBlockStatusModelToJson(
  _WithdrawalBlockStatusModel instance,
) => <String, dynamic>{
  'blocked': instance.blocked,
  'last_withdrawal_at': instance.lastWithdrawalAt,
  'block_remaining_seconds': instance.blockRemainingSeconds,
};
