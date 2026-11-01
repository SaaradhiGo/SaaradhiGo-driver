// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarningsSummaryModel _$EarningsSummaryModelFromJson(
  Map<String, dynamic> json,
) => _EarningsSummaryModel(
  totalEarned: json['total_earned'] == null
      ? '0.00'
      : moneyFromJson(json['total_earned']),
  totalCommission: nullableMoneyFromJson(json['total_commission']),
  totalTrips: json['total_trips'] == null
      ? 0
      : intFromJson(json['total_trips']),
  todayEarned: json['today_earned'] == null
      ? '0.00'
      : moneyFromJson(json['today_earned']),
  todayTrips: json['today_trips'] == null
      ? 0
      : intFromJson(json['today_trips']),
  commissionPercent: nullableNumFromJson(json['commission_percent']),
  commissionPercentMixed: nullableBoolFromJson(
    json['commission_percent_mixed'],
  ),
  totalNet: nullableMoneyFromJson(json['total_net']),
  promoPaidByPlatform: nullableMoneyFromJson(json['promo_paid_by_platform']),
  todayPromoPaidByPlatform: nullableMoneyFromJson(
    json['today_promo_paid_by_platform'],
  ),
  promoPaidLabel: json['promo_paid_label'] as String?,
  taxCollected: nullableMoneyFromJson(json['tax_collected']),
  regulatoryFeesCollected: nullableMoneyFromJson(
    json['regulatory_fees_collected'],
  ),
  taxCollectedLabel: json['tax_collected_label'] as String?,
  incentiveRewards: nullableMoneyFromJson(json['incentive_rewards']),
  referralRewards: nullableMoneyFromJson(json['referral_rewards']),
  incentiveCommission: json['incentive_commission'] as String?,
  incentiveTax: json['incentive_tax'] as String?,
);

Map<String, dynamic> _$EarningsSummaryModelToJson(
  _EarningsSummaryModel instance,
) => <String, dynamic>{
  'total_earned': instance.totalEarned,
  'total_commission': instance.totalCommission,
  'total_trips': instance.totalTrips,
  'today_earned': instance.todayEarned,
  'today_trips': instance.todayTrips,
  'commission_percent': instance.commissionPercent,
  'commission_percent_mixed': instance.commissionPercentMixed,
  'total_net': instance.totalNet,
  'promo_paid_by_platform': instance.promoPaidByPlatform,
  'today_promo_paid_by_platform': instance.todayPromoPaidByPlatform,
  'promo_paid_label': instance.promoPaidLabel,
  'tax_collected': instance.taxCollected,
  'regulatory_fees_collected': instance.regulatoryFeesCollected,
  'tax_collected_label': instance.taxCollectedLabel,
  'incentive_rewards': instance.incentiveRewards,
  'referral_rewards': instance.referralRewards,
  'incentive_commission': instance.incentiveCommission,
  'incentive_tax': instance.incentiveTax,
};
