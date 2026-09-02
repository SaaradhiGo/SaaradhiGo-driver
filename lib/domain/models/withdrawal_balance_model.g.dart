// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WithdrawalBalanceModel _$WithdrawalBalanceModelFromJson(
  Map<String, dynamic> json,
) => _WithdrawalBalanceModel(
  availableBalance: json['available_balance'] == null
      ? 0.0
      : doubleFromJson(json['available_balance']),
  blocked: json['blocked'] == null ? false : boolFromJson(json['blocked']),
  blockRemainingSeconds: nullableIntFromJson(json['block_remaining_seconds']),
  feePercent: json['fee_percent'] == null
      ? 0.0
      : doubleFromJson(json['fee_percent']),
  minimumWithdrawal: json['minimum_withdrawal'] == null
      ? 500.0
      : doubleFromJson(json['minimum_withdrawal']),
);

Map<String, dynamic> _$WithdrawalBalanceModelToJson(
  _WithdrawalBalanceModel instance,
) => <String, dynamic>{
  'available_balance': instance.availableBalance,
  'blocked': instance.blocked,
  'block_remaining_seconds': instance.blockRemainingSeconds,
  'fee_percent': instance.feePercent,
  'minimum_withdrawal': instance.minimumWithdrawal,
};
