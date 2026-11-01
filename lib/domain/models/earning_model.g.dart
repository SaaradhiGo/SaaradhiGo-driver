// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarningModel _$EarningModelFromJson(
  Map<String, dynamic> json,
) => _EarningModel(
  id: json['id'] == null ? 0 : intFromJson(json['id']),
  tripId: nullableIntFromJson(_readTripId(json, 'trip_id')),
  amountCollected: nullableMoneyFromJson(_readGross(json, 'amount_collected')),
  platformFee: nullableMoneyFromJson(_readCommission(json, 'platform_fee')),
  netEarning: nullableMoneyFromJson(_readNet(json, 'net_earning')),
  commissionPercent: nullableNumFromJson(json['commission_percent']),
  createdAt: json['created_at'] as String?,
  method: json['method'] as String?,
  cashInHand: nullableBoolFromJson(json['cash_in_hand']),
  cashToCollect: nullableMoneyFromJson(json['cash_to_collect']),
  promoPaidByPlatform: nullableMoneyFromJson(json['promo_paid_by_platform']),
  promoPaidLabel: json['promo_paid_label'] as String?,
  promoCreditedToWallet: nullableBoolFromJson(json['promo_credited_to_wallet']),
  taxCollected: nullableMoneyFromJson(json['tax_collected']),
  regulatoryFeeCollected: nullableMoneyFromJson(
    json['regulatory_fee_collected'],
  ),
  deductions: json['deductions'] == null
      ? const <EarningDeduction>[]
      : deductionsFromJson(json['deductions']),
);

Map<String, dynamic> _$EarningModelToJson(_EarningModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'amount_collected': instance.amountCollected,
      'platform_fee': instance.platformFee,
      'net_earning': instance.netEarning,
      'commission_percent': instance.commissionPercent,
      'created_at': instance.createdAt,
      'method': instance.method,
      'cash_in_hand': instance.cashInHand,
      'cash_to_collect': instance.cashToCollect,
      'promo_paid_by_platform': instance.promoPaidByPlatform,
      'promo_paid_label': instance.promoPaidLabel,
      'promo_credited_to_wallet': instance.promoCreditedToWallet,
      'tax_collected': instance.taxCollected,
      'regulatory_fee_collected': instance.regulatoryFeeCollected,
      'deductions': deductionsToJson(instance.deductions),
    };
