// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WithdrawalModel _$WithdrawalModelFromJson(Map<String, dynamic> json) =>
    _WithdrawalModel(
      id: json['id'] == null ? 0 : intFromJson(json['id']),
      amount: json['amount'] == null ? '0.00' : moneyFromJson(json['amount']),
      status: json['status'] as String? ?? 'pending',
      requestedAt: json['requested_at'] as String?,
    );

Map<String, dynamic> _$WithdrawalModelToJson(_WithdrawalModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'status': instance.status,
      'requested_at': instance.requestedAt,
    };
