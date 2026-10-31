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
};
