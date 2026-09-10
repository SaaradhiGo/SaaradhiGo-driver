import '../models/earnings_model.dart';
import 'api_client.dart';

class EarningsService {
  /// Fetch earnings summary
  static Future<EarningsSummaryModel?> getEarningsSummary({
    String? period,
  }) async {
    final queryParams = <String, String>{};
    if (period != null) {
      queryParams['period'] = period;
    }

    final response = await ApiClient.get(
      '/driver/earnings/summary/',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.success && response.data != null) {
      return EarningsSummaryModel.fromJson(response.data!);
    }
    return null;
  }

  /// Fetch earnings history list
  static Future<List<EarningModel>> getEarningsList({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await ApiClient.get(
      '/driver/earnings/',
      queryParams: {'page': page.toString(), 'page_size': pageSize.toString()},
    );

    if (response.success && response.data != null) {
      final results = response.data!['results'] as List?;
      if (results != null) {
        return results
            .map((e) => EarningModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }
}
