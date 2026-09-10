import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/earning_model.dart';
import '../../../../domain/models/earnings_summary_model.dart';
import '../../../../domain/models/withdrawal_balance_model.dart';
import '../../../../domain/models/withdrawal_model.dart';
import '../../domain/repositories/earnings_repository.dart';
import 'earnings_providers.dart';

/// Outcome of one earnings-section load. Each dashboard section (summary,
/// earnings list, withdrawal balance, withdrawal history) is loaded
/// independently so a single failing endpoint can no longer blank the whole
/// dashboard via an all-or-nothing `Future.wait`.
sealed class _SectionResult<T> {
  const _SectionResult();
}

class _SectionOk<T> extends _SectionResult<T> {
  const _SectionOk(this.value);
  final T value;
}

class _SectionFailed<T> extends _SectionResult<T> {
  const _SectionFailed(this.error);
  final Object error;
}

Future<_SectionResult<T>> _guardSection<T>(Future<T> Function() run) async {
  try {
    return _SectionOk(await run());
  } catch (e) {
    // Logged (never user-facing) so a healthy section can still be shown.
    AppLogger.w('Earnings section failed to load', e);
    return _SectionFailed(e);
  }
}

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

  /// Loads the four dashboard sections in parallel, each isolated. Returns the
  /// freshly-loaded sections wrapped so callers only need the ones that
  /// succeeded (failed sections fall back to the previous state).
  Future<
    ({
      _SectionResult<EarningsSummaryModel?> summary,
      _SectionResult<List<EarningModel>> earningsList,
      _SectionResult<WithdrawalBalanceModel?> withdrawalBalance,
      _SectionResult<List<WithdrawalModel>> withdrawalHistory,
    })
  >
  _loadAllSections() async {
    final periodStr = _getPeriodString(state.selectedPeriodIndex);
    final summary = await _guardSection<EarningsSummaryModel?>(
      () => _repository.getEarningsSummary(period: periodStr),
    );
    final earningsList = await _guardSection<List<EarningModel>>(
      () => _repository.getEarningsList(),
    );
    final withdrawalBalance = await _guardSection<WithdrawalBalanceModel?>(
      () => _repository.getWithdrawalBalance(),
    );
    final withdrawalHistory = await _guardSection<List<WithdrawalModel>>(
      () => _repository.getWithdrawalHistory(),
    );
    return (
      summary: summary,
      earningsList: earningsList,
      withdrawalBalance: withdrawalBalance,
      withdrawalHistory: withdrawalHistory,
    );
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final hadSummary = state.summary != null;
    final sections = await _loadAllSections();

    var nextSummary = state.summary;
    var nextEarningsList = state.earningsList;
    var nextBalance = state.withdrawalBalance;
    var nextHistory = state.withdrawalHistory;
    String? fatalError;

    if (sections.summary case _SectionOk(:final value)) {
      nextSummary = value;
    } else if (!hadSummary) {
      // Nothing to fall back to: the dashboard needs a summary to render.
      fatalError =
          'Unable to load earnings summary. Pull down to retry, or check your connection.';
    }

    if (sections.earningsList case _SectionOk(:final value)) {
      nextEarningsList = value;
    }
    if (sections.withdrawalBalance case _SectionOk(:final value)) {
      nextBalance = value;
    }
    if (sections.withdrawalHistory case _SectionOk(:final value)) {
      nextHistory = value;
    }

    state = state.copyWith(
      isLoading: false,
      summary: nextSummary,
      earningsList: nextEarningsList,
      withdrawalBalance: nextBalance,
      withdrawalHistory: nextHistory,
      errorMessage: fatalError,
    );
  }

  Future<void> setPeriod(int periodIndex) async {
    if (state.selectedPeriodIndex == periodIndex) return;
    final previousIndex = state.selectedPeriodIndex;
    state = state.copyWith(selectedPeriodIndex: periodIndex, isLoading: true);
    final result = await _guardSection<EarningsSummaryModel?>(
      () =>
          _repository.getEarningsSummary(period: _getPeriodString(periodIndex)),
    );
    switch (result) {
      case _SectionOk(:final value):
        state = state.copyWith(isLoading: false, summary: value);
      case _SectionFailed():
        // Revert the filter so the visible period label stays in sync with the
        // summary that is still on screen.
        state = state.copyWith(
          isLoading: false,
          selectedPeriodIndex: previousIndex,
          errorMessage: 'Failed to filter earnings. Try again.',
        );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, errorMessage: null);
    final hadSummary = state.summary != null;
    final sections = await _loadAllSections();

    var nextSummary = state.summary;
    var nextEarningsList = state.earningsList;
    var nextBalance = state.withdrawalBalance;
    var nextHistory = state.withdrawalHistory;

    if (sections.summary case _SectionOk(:final value)) {
      nextSummary = value;
    }
    if (sections.earningsList case _SectionOk(:final value)) {
      nextEarningsList = value;
    }
    if (sections.withdrawalBalance case _SectionOk(:final value)) {
      nextBalance = value;
    }
    if (sections.withdrawalHistory case _SectionOk(:final value)) {
      nextHistory = value;
    }

    // On refresh keep whatever loaded; only surface a fatal panel when nothing
    // was previously available AND the summary still failed to load.
    final nothingLoaded =
        nextSummary == null &&
        nextEarningsList.isEmpty &&
        nextBalance == null &&
        nextHistory.isEmpty;

    state = state.copyWith(
      isRefreshing: false,
      summary: nextSummary,
      earningsList: nextEarningsList,
      withdrawalBalance: nextBalance,
      withdrawalHistory: nextHistory,
      errorMessage: (!hadSummary && nothingLoaded && nextSummary == null)
          ? 'Unable to refresh earnings data. Check your connection.'
          : null,
    );
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

      // Refresh balances and history after a successful withdrawal request.
      // Each is isolated: a failed refresh should not fail the withdrawal UX.
      final balanceResult = await _guardSection<WithdrawalBalanceModel?>(
        () => _repository.getWithdrawalBalance(),
      );
      final historyResult = await _guardSection<List<WithdrawalModel>>(
        () => _repository.getWithdrawalHistory(),
      );

      final nextBalance = switch (balanceResult) {
        _SectionOk(:final value) => value,
        _SectionFailed() => state.withdrawalBalance,
      };
      final nextHistory = switch (historyResult) {
        _SectionOk(:final value) => value,
        _SectionFailed() => state.withdrawalHistory,
      };

      state = state.copyWith(
        isSubmittingWithdrawal: false,
        withdrawalBalance: nextBalance,
        withdrawalHistory: nextHistory,
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
