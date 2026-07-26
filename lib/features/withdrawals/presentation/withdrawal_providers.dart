import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/withdrawal.dart';

final withdrawalBalanceProvider =
    FutureProvider.autoDispose<WithdrawalBalance>((ref) {
  return ref.watch(withdrawalRepositoryProvider).fetchBalance();
});

final withdrawalHistoryProvider =
    FutureProvider.autoDispose<List<WithdrawalRequest>>((ref) {
  return ref.watch(withdrawalRepositoryProvider).fetchHistory();
});

/// Submits a payout request.
///
/// Kept as a controller rather than a one-shot call so the button has a real
/// busy state: this is money leaving the platform, and a driver double-
/// tapping because nothing happened is exactly how duplicate requests get
/// filed for the ops team to untangle.
class WithdrawalController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> request(double amount) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(withdrawalRepositoryProvider).requestWithdrawal(amount);
      // Balance and history both moved.
      ref.invalidate(withdrawalBalanceProvider);
      ref.invalidate(withdrawalHistoryProvider);
      state = const AsyncValue.data(null);
      return true;
    } on Object catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final withdrawalControllerProvider =
    AsyncNotifierProvider<WithdrawalController, void>(WithdrawalController.new);
