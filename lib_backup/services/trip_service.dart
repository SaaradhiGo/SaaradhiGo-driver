import '../models/trip_model.dart';
import 'api_client.dart';

class TripService {
  /// Fetch driver's trip history with optional status filter.
  static Future<List<TripModel>> getDriverHistory({
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (status != null && status != 'all') {
      queryParams['status'] = status;
    }

    final response = await ApiClient.get(
      '/ride/driver-history/',
      queryParams: queryParams,
    );

    if (response.success && response.data != null) {
      final results = response.data!['results'] as List?;
      if (results != null) {
        return results
            .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  /// Fetch details of a specific trip.
  static Future<TripModel?> getTripDetails(int tripId) async {
    final response = await ApiClient.get('/ride/trip/$tripId/');

    if (response.success && response.data != null) {
      return TripModel.fromJson(response.data!);
    }
    return null;
  }

  /// Fetch raw details of a specific trip, useful when we need all fields (e.g. for session hydration).
  static Future<Map<String, dynamic>?> getRawTripDetails(int tripId) async {
    final response = await ApiClient.get('/ride/trip/$tripId/');

    if (response.success && response.data != null) {
      return response.data;
    }
    return null;
  }
}
