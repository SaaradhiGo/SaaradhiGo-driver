import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/earning_model.dart';
import '../../../../domain/models/earnings_summary_model.dart';
import '../../../../domain/models/withdrawal_balance_model.dart';
import '../../../../domain/models/withdrawal_model.dart';

part 'earnings_state.freezed.dart';

@freezed
abstract class EarningsState with _$EarningsState {
  const factory EarningsState({
    EarningsSummaryModel? summary,
    @Default([]) List<EarningModel> earningsList,
    WithdrawalBalanceModel? withdrawalBalance,
    @Default([]) List<WithdrawalModel> withdrawalHistory,
    @Default(0)
    int selectedPeriodIndex, // 0: Today, 1: This Week, 2: This Month
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    @Default(false) bool isSubmittingWithdrawal,
    String? errorMessage,
    String? withdrawalSuccessMessage,
    double? cashToCollect,
  }) = _EarningsState;
}
