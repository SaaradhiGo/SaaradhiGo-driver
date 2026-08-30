import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/earnings_repository.dart';
import 'earnings_providers.dart';

class EarningsNotifier extends Notifier<EarningsState> {
  late EarningsRepository _repository;

  @override
  EarningsState build() {
    _repository = ref.watch(earningsRepositoryProvider);
    return const EarningsState();
  }

  String _getPeriodString(int index) {
    switch (index) {
      case 1:
        return 'this_week';
      case 2:
        return 'this_month';
      case 0:
      default:
        return 'today';
    }
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final periodStr = _getPeriodString(state.selectedPeriodIndex);
      final results = await Future.wait([
        _repository.getEarningsSummary(period: periodStr),
        _repository.getEarningsList(),
        _repository.getWithdrawalBalance(),
        _repository.getWithdrawalHistory(),
      ]);

      state = state.copyWith(
        isLoading: false,
        summary: results[0] as dynamic,
        earningsList: results[1] as dynamic,
        withdrawalBalance: results[2] as dynamic,
        withdrawalHistory: results[3] as dynamic,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load earnings: ${e.toString()}',
      );
    }
  }

  Future<void> setPeriod(int periodIndex) async {
    if (state.selectedPeriodIndex == periodIndex) return;
    state = state.copyWith(selectedPeriodIndex: periodIndex, isLoading: true);
    try {
      final periodStr = _getPeriodString(periodIndex);
      final summary = await _repository.getEarningsSummary(period: periodStr);
      state = state.copyWith(isLoading: false, summary: summary);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to filter earnings: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, errorMessage: null);
    try {
      final periodStr = _getPeriodString(state.selectedPeriodIndex);
      final results = await Future.wait([
        _repository.getEarningsSummary(period: periodStr),
        _repository.getEarningsList(),
        _repository.getWithdrawalBalance(),
        _repository.getWithdrawalHistory(),
      ]);

      state = state.copyWith(
        isRefreshing: false,
        summary: results[0] as dynamic,
        earningsList: results[1] as dynamic,
        withdrawalBalance: results[2] as dynamic,
        withdrawalHistory: results[3] as dynamic,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: 'Failed to refresh data.',
      );
    }
  }

  Future<bool> requestWithdrawal(double amount) async {
    final balance = state.withdrawalBalance;
    if (balance == null) {
      state = state.copyWith(
        errorMessage: 'Withdrawal balance not loaded. Try again.',
      );
      return false;
    }

    if (balance.blocked) {
      state = state.copyWith(
        errorMessage: 'Withdrawals are currently locked for your account.',
      );
      return false;
    }

    if (amount < balance.minimumWithdrawal) {
      state = state.copyWith(
        errorMessage:
            'Minimum withdrawal amount is ₹${balance.minimumWithdrawal.toStringAsFixed(2)}',
      );
      return false;
    }

    if (amount > balance.availableBalance) {
      state = state.copyWith(
        errorMessage: 'Entered amount exceeds available balance.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmittingWithdrawal: true,
      errorMessage: null,
      withdrawalSuccessMessage: null,
    );

    try {
      final withdrawal = await _repository.requestWithdrawal(amount);

      // Refresh balances and history after successful withdrawal request
      final updatedBalance = await _repository.getWithdrawalBalance();
      final updatedHistory = await _repository.getWithdrawalHistory();

      state = state.copyWith(
        isSubmittingWithdrawal: false,
        withdrawalBalance: updatedBalance,
        withdrawalHistory: updatedHistory,
        withdrawalSuccessMessage:
            'Withdrawal request of ₹${amount.toStringAsFixed(2)} submitted successfully (ID: ${withdrawal.id}).',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmittingWithdrawal: false,
        errorMessage: 'Withdrawal request failed: ${e.toString()}',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, withdrawalSuccessMessage: null);
  }

  void setCashToCollect(double? amount) {
    state = state.copyWith(cashToCollect: amount);
  }
}
