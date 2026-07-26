import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/withdrawal.dart';
import '../domain/withdrawal_repository.dart';

class WithdrawalRepositoryImpl implements WithdrawalRepository {
  WithdrawalRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<WithdrawalBalance> fetchBalance() async {
    final data = await _api.get(ApiEndpoints.withdrawalBalance);
    return WithdrawalBalance.fromJson(data);
  }

  @override
  Future<WithdrawalRequest> requestWithdrawal(double amount) async {
    final data = await _api.post(
      ApiEndpoints.withdrawalRequest,
      // Sent as a string: the backend parses into a Decimal, and a double
      // like 1500.0000000002 is exactly the kind of value that trips a
      // max_digits validation error.
      body: {'amount': amount.toStringAsFixed(2)},
    );
    return WithdrawalRequest.fromJson(data);
  }

  @override
  Future<List<WithdrawalRequest>> fetchHistory({int page = 1}) async {
    final list = await _api.getList(
      ApiEndpoints.withdrawalHistory,
      query: {'page': page},
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(WithdrawalRequest.fromJson)
        .toList(growable: false);
  }
}
