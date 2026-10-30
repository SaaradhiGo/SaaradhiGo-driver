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
  feeDisplay: json['fee_display'] as String?,
  minimumWithdrawal: json['minimum_withdrawal'] == null
      ? 0.0
      : doubleFromJson(json['minimum_withdrawal']),
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$WithdrawalBalanceModelToJson(
  _WithdrawalBalanceModel instance,
) => <String, dynamic>{
  'available_balance': instance.availableBalance,
  'blocked': instance.blocked,
  'block_remaining_seconds': instance.blockRemainingSeconds,
  'fee_percent': instance.feePercent,
  'fee_display': instance.feeDisplay,
  'minimum_withdrawal': instance.minimumWithdrawal,
  'currency': instance.currency,
};
