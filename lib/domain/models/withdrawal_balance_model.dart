import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';

part 'withdrawal_balance_model.freezed.dart';
part 'withdrawal_balance_model.g.dart';

@freezed
abstract class WithdrawalBalanceModel with _$WithdrawalBalanceModel {
  const factory WithdrawalBalanceModel({
    @JsonKey(name: 'available_balance', fromJson: doubleFromJson)
    @Default(0.0)
    double availableBalance,
    @JsonKey(fromJson: boolFromJson) @Default(false) bool blocked,
    @JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson)
    int? blockRemainingSeconds,
    @JsonKey(name: 'fee_percent', fromJson: doubleFromJson)
    @Default(0.0)
    double feePercent,
    @JsonKey(name: 'minimum_withdrawal', fromJson: doubleFromJson)
    @Default(500.0)
    double minimumWithdrawal,
  }) = _WithdrawalBalanceModel;

  factory WithdrawalBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalBalanceModelFromJson(json);
}
