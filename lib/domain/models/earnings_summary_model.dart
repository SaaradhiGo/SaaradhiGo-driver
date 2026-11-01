import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';

part 'earnings_summary_model.freezed.dart';
part 'earnings_summary_model.g.dart';

@freezed
abstract class EarningsSummaryModel with _$EarningsSummaryModel {
  const factory EarningsSummaryModel({
    @JsonKey(name: 'total_earned', fromJson: moneyFromJson)
    @Default('0.00')
    String totalEarned,
    // Commission fields are nullable on purpose: the app shows what the API
    // returns and shows nothing for a line the API did not send. No default.
    @JsonKey(name: 'total_commission', fromJson: nullableMoneyFromJson)
    String? totalCommission,
    @JsonKey(name: 'total_trips', fromJson: intFromJson)
    @Default(0)
    int totalTrips,
    @JsonKey(name: 'today_earned', fromJson: moneyFromJson)
    @Default('0.00')
    String todayEarned,
    @JsonKey(name: 'today_trips', fromJson: intFromJson)
    @Default(0)
    int todayTrips,
    @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson)
    num? commissionPercent,
    @JsonKey(name: 'commission_percent_mixed', fromJson: nullableBoolFromJson)
    bool? commissionPercentMixed,
    // The API's own net (sum of the trips' nets). Preferred over deriving it.
    @JsonKey(name: 'total_net', fromJson: nullableMoneyFromJson)
    String? totalNet,
    // Module 12 / US pass-through / rewards. Additive: null when the API does
    // not send them, and the screens hide a line whose value is absent or zero.
    @JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson)
    String? promoPaidByPlatform,
    @JsonKey(
      name: 'today_promo_paid_by_platform',
      fromJson: nullableMoneyFromJson,
    )
    String? todayPromoPaidByPlatform,
    @JsonKey(name: 'promo_paid_label') String? promoPaidLabel,
    @JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson)
    String? taxCollected,
    @JsonKey(name: 'regulatory_fees_collected', fromJson: nullableMoneyFromJson)
    String? regulatoryFeesCollected,
    @JsonKey(name: 'tax_collected_label') String? taxCollectedLabel,
    @JsonKey(name: 'incentive_rewards', fromJson: nullableMoneyFromJson)
    String? incentiveRewards,
    @JsonKey(name: 'referral_rewards', fromJson: nullableMoneyFromJson)
    String? referralRewards,
    @JsonKey(name: 'incentive_commission') String? incentiveCommission,
    @JsonKey(name: 'incentive_tax') String? incentiveTax,
  }) = _EarningsSummaryModel;

  factory EarningsSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$EarningsSummaryModelFromJson(json);
}
