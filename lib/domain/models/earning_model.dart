import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';

part 'earning_model.freezed.dart';
part 'earning_model.g.dart';

Object? _readTripId(Map<dynamic, dynamic> m, String _) =>
    m['trip_id_val'] ?? m['trip_id'];
Object? _readGross(Map<dynamic, dynamic> m, String _) =>
    m['amount'] ?? m['amount_collected'];
Object? _readCommission(Map<dynamic, dynamic> m, String _) =>
    m['commission'] ?? m['platform_fee'];
Object? _readNet(Map<dynamic, dynamic> m, String _) =>
    m['net_amount'] ?? m['net_earning'];

@freezed
abstract class EarningModel with _$EarningModel {
  const factory EarningModel({
    @JsonKey(fromJson: intFromJson) @Default(0) int id,
    // The settlements endpoint sends `trip_id_val`, `amount`, `commission`,
    // `net_amount` and `commission_percent`; the older names are still read as
    // a fallback. Money and the rate are nullable: nothing is shown for a
    // value the API did not send, and no default is ever invented.
    @JsonKey(
      name: 'trip_id',
      fromJson: nullableIntFromJson,
      readValue: _readTripId,
    )
    int? tripId,
    @JsonKey(
      name: 'amount_collected',
      fromJson: nullableMoneyFromJson,
      readValue: _readGross,
    )
    String? amountCollected,
    @JsonKey(
      name: 'platform_fee',
      fromJson: nullableMoneyFromJson,
      readValue: _readCommission,
    )
    String? platformFee,
    @JsonKey(
      name: 'net_earning',
      fromJson: nullableMoneyFromJson,
      readValue: _readNet,
    )
    String? netEarning,
    @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson)
    num? commissionPercent,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _EarningModel;

  factory EarningModel.fromJson(Map<String, dynamic> json) =>
      _$EarningModelFromJson(json);
}
