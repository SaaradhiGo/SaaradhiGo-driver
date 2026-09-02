import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';

part 'earning_model.freezed.dart';
part 'earning_model.g.dart';

@freezed
abstract class EarningModel with _$EarningModel {
  const factory EarningModel({
    @JsonKey(fromJson: intFromJson) @Default(0) int id,
    @JsonKey(name: 'trip_id', fromJson: nullableIntFromJson) int? tripId,
    @JsonKey(name: 'amount_collected', fromJson: moneyFromJson)
    @Default('0.00')
    String amountCollected,
    @JsonKey(name: 'platform_fee', fromJson: moneyFromJson)
    @Default('0.00')
    String platformFee,
    @JsonKey(name: 'net_earning', fromJson: moneyFromJson)
    @Default('0.00')
    String netEarning,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _EarningModel;

  factory EarningModel.fromJson(Map<String, dynamic> json) =>
      _$EarningModelFromJson(json);
}
