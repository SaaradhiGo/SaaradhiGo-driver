import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';

part 'withdrawal_model.freezed.dart';
part 'withdrawal_model.g.dart';

@freezed
abstract class WithdrawalModel with _$WithdrawalModel {
  const factory WithdrawalModel({
    @JsonKey(fromJson: intFromJson) @Default(0) int id,
    @JsonKey(fromJson: moneyFromJson) @Default('0.00') String amount,
    @Default('pending') String status,
    @JsonKey(name: 'requested_at') String? requestedAt,
  }) = _WithdrawalModel;

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalModelFromJson(json);
}
