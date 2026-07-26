import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/earnings.dart';
import '../domain/earnings_repository.dart';

class EarningsRepositoryImpl implements EarningsRepository {
  EarningsRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<EarningsSummary> fetchSummary() async {
    final data = await _api.get(ApiEndpoints.earningsSummary);
    return EarningsSummary.fromJson(data);
  }

  @override
  Future<List<EarningEntry>> fetchEntries({
    int page = 1,
    int pageSize = 50,
  }) async {
    final list = await _api.getList(
      ApiEndpoints.earnings,
      query: {'page': page, 'page_size': pageSize},
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(EarningEntry.fromJson)
        .toList(growable: false);
  }
}
