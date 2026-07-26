import 'trip.dart';

abstract class TripRepository {
  /// The authoritative active trip, from `GET /ride/active/`.
  ///
  /// This is the reconciliation source on cold start: the Hive-style local
  /// snapshot gets the UI on screen instantly, then this decides what is
  /// actually true. Returns null when the driver has no live trip.
  Future<Trip?> fetchActiveTrip();

  Future<Trip> fetchTrip(int tripId);

  /// Driver-initiated cancellation. Only legal before the trip starts; the
  /// server applies the penalty ledger and the rolling cancellation cooldown.
  Future<void> cancelTrip({
    required int tripId,
    required String reason,
    String? note,
  });

  /// Signed URL for the rider's receipt PDF, for the post-trip screen.
  Future<String?> receiptPdfUrl(int tripId);
}
