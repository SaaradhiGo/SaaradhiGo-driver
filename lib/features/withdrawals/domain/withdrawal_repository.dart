import 'withdrawal.dart';

abstract class WithdrawalRepository {
  Future<WithdrawalBalance> fetchBalance();

  /// Creates a withdrawal request. The server validates KYC, the daily
  /// limit, the minimum, and that no other request is pending — all of which
  /// can reject this call with a driver-readable message.
  Future<WithdrawalRequest> requestWithdrawal(double amount);

  Future<List<WithdrawalRequest>> fetchHistory({int page = 1});
}
