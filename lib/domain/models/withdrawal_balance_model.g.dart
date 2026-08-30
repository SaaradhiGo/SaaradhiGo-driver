// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WithdrawalBalanceModel _$WithdrawalBalanceModelFromJson(
  Map<String, dynamic> json,
) => _WithdrawalBalanceModel(
  availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
  blocked: json['blocked'] as bool? ?? false,
  blockRemainingSeconds: (json['block_remaining_seconds'] as num?)?.toInt(),
  feePercent: (json['fee_percent'] as num?)?.toDouble() ?? 0.0,
  minimumWithdrawal: (json['minimum_withdrawal'] as num?)?.toDouble() ?? 500.0,
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
