import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../domain/trip.dart';
import '../domain/trip_repository.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Trip?> fetchActiveTrip() async {
    try {
      final data = await _api.get(ApiEndpoints.activeTrip);
      if (data.isEmpty) return null;
      // The endpoint answers with an empty payload (or an explicit null trip)
      // when nothing is live; treat both as "no active trip" rather than
      // constructing a Trip with id 0.
      final hasId = data['trip_id'] != null || data['id'] != null;
      if (!hasId) return null;
      return Trip.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Trip> fetchTrip(int tripId) async {
    final data = await _api.get(ApiEndpoints.tripDetail(tripId));
    return Trip.fromJson(data);
  }

  @override
  Future<void> cancelTrip({
    required int tripId,
    required String reason,
    String? note,
  }) async {
    await _api.post(
      ApiEndpoints.driverCancelTrip(tripId),
      body: {
        'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  @override
  Future<String?> receiptPdfUrl(int tripId) async {
    try {
      final data = await _api.get(ApiEndpoints.receiptPdf(tripId));
      return data['pdf_url'] as String?;
    } on ApiException catch (e) {
      // Receipts are issued by a Celery task after the trip commits, so a
      // 404 immediately after completion is expected, not an error.
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
