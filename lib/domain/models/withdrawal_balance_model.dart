import 'package:freezed_annotation/freezed_annotation.dart';

part 'withdrawal_balance_model.freezed.dart';
part 'withdrawal_balance_model.g.dart';

@freezed
abstract class WithdrawalBalanceModel with _$WithdrawalBalanceModel {
  const factory WithdrawalBalanceModel({
    @JsonKey(name: 'available_balance') @Default(0.0) double availableBalance,
    @Default(false) bool blocked,
    @JsonKey(name: 'block_remaining_seconds') int? blockRemainingSeconds,
    @JsonKey(name: 'fee_percent') @Default(0.0) double feePercent,
    @JsonKey(name: 'minimum_withdrawal')
    @Default(500.0)
    double minimumWithdrawal,
  }) = _WithdrawalBalanceModel;

  factory WithdrawalBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalBalanceModelFromJson(json);
}
