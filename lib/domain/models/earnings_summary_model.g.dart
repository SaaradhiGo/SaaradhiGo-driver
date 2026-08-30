// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarningsSummaryModel _$EarningsSummaryModelFromJson(
  Map<String, dynamic> json,
) => _EarningsSummaryModel(
  totalEarned: json['total_earned'] as String? ?? '0.00',
  totalCommission: json['total_commission'] as String? ?? '0.00',
  totalTrips: (json['total_trips'] as num?)?.toInt() ?? 0,
  todayEarned: json['today_earned'] as String? ?? '0.00',
  todayTrips: (json['today_trips'] as num?)?.toInt() ?? 0,
  commissionPercent: json['commission_percent'] as num? ?? 10,
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
};
