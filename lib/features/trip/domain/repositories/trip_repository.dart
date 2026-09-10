import '../../../../domain/models/trip_model.dart';

/// Domain contract for ride-lifecycle REST operations.
abstract class TripRepository {
  /// The driver's current active trip, or null when none is in flight.
  Future<TripModel?> getActiveTrip();

  /// Cancels an accepted/reached trip with a required [reason].
  Future<void> driverCancel(int tripId, {required String reason, String? note});
}
