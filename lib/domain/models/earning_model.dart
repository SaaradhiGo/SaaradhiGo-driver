import 'package:freezed_annotation/freezed_annotation.dart';

part 'earning_model.freezed.dart';
part 'earning_model.g.dart';

@freezed
abstract class EarningModel with _$EarningModel {
  const factory EarningModel({
    required int id,
    @JsonKey(name: 'trip_id') int? tripId,
    @JsonKey(name: 'amount_collected') @Default('0.00') String amountCollected,
    @JsonKey(name: 'platform_fee') @Default('0.00') String platformFee,
    @JsonKey(name: 'net_earning') @Default('0.00') String netEarning,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _EarningModel;

  factory EarningModel.fromJson(Map<String, dynamic> json) =>
      _$EarningModelFromJson(json);
}
