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
  }) = _EarningsSummaryModel;

  factory EarningsSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$EarningsSummaryModelFromJson(json);
}
