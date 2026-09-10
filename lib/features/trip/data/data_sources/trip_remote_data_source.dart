import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../domain/models/trip_model.dart';

/// REST calls backing the ride lifecycle.
///
/// The realtime path is the trip WebSocket; REST is used only for crash
/// recovery (`GET /ride/active/`) and the driver-initiated cancel that has no
/// socket action from a pre-trip state.
abstract class TripRemoteDataSource {
  /// Returns the driver's current active trip, or null when there is none
  /// (backend replies `404 NO_ACTIVE_TRIP`).
  Future<TripModel?> getActiveTrip();

  /// Cancels an accepted/reached trip. `reason` is required by the backend;
  /// this endpoint does NOT emit a WebSocket broadcast.
  Future<void> driverCancel(int tripId, {required String reason, String? note});
}

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  TripRemoteDataSourceImpl(this.dio);

  final Dio dio;

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map) {
      final rawData =
          responseData['data'] ?? responseData['trip'] ?? responseData;
      if (rawData is Map) {
        if (rawData['trip'] is Map) {
          return Map<String, dynamic>.from(rawData['trip'] as Map);
        }
        return Map<String, dynamic>.from(rawData);
      }
    }
    return <String, dynamic>{};
  }

  @override
  Future<TripModel?> getActiveTrip() async {
    try {
      final response = await dio.get(ApiEndpoints.activeTrip);
      final data = _extractData(response.data);
      if (data.isEmpty) return null;
      // Ensure there is an actual trip id in the payload
      if (data['id'] == null && data['trip_id'] == null) return null;
      return TripModel.fromJson(data);
    } on DioException catch (e) {
      // 404 is the documented "no active trip" signal, not a failure.
      if (e.response?.statusCode == 404) return null;
      rethrow;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> driverCancel(
    int tripId, {
    required String reason,
    String? note,
  }) async {
    await dio.post(
      ApiEndpoints.driverCancelTrip(tripId.toString()),
      data: <String, dynamic>{
        'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }
}
