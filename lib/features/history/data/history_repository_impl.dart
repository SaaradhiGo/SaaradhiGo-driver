import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../trip/domain/trip.dart';
import '../domain/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<Trip>> fetchHistory({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final list = await _api.getList(
      ApiEndpoints.driverHistory,
      query: {
        'page': page,
        'page_size': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(Trip.fromJson)
        .toList(growable: false);
  }
}
