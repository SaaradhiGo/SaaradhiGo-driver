// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_block_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WithdrawalBlockStatusModel _$WithdrawalBlockStatusModelFromJson(
  Map<String, dynamic> json,
) => _WithdrawalBlockStatusModel(
  blocked: json['blocked'] as bool? ?? false,
  lastWithdrawalAt: json['last_withdrawal_at'] as String?,
  blockRemainingSeconds: (json['block_remaining_seconds'] as num?)?.toInt(),
);

Map<String, dynamic> _$WithdrawalBlockStatusModelToJson(
  _WithdrawalBlockStatusModel instance,
) => <String, dynamic>{
  'blocked': instance.blocked,
  'last_withdrawal_at': instance.lastWithdrawalAt,
  'block_remaining_seconds': instance.blockRemainingSeconds,
};
