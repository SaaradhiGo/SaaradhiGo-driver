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
    // The fee text exactly as the server charges it (null when there is no fee,
    // so the app shows nothing). The app never builds this from feePercent.
    @JsonKey(name: 'fee_display') String? feeDisplay,
    // No client-side default: the minimum is the driver's country's, and the
    // server is the authority (it used to default to 500 for everyone).
    @JsonKey(name: 'minimum_withdrawal', fromJson: doubleFromJson)
    @Default(0.0)
    double minimumWithdrawal,
    // The currency of every amount here, named by the API.
    @JsonKey(name: 'currency') String? currency,
  }) = _WithdrawalBalanceModel;

  factory WithdrawalBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalBalanceModelFromJson(json);
}
