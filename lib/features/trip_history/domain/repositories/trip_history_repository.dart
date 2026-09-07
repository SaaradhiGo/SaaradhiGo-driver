import 'package:flutter/material.dart';
import '../../../../domain/models/trip_model.dart';

/// Contract for driver trip history and individual trip details.
abstract class TripHistoryRepository {
  /// Fetches paginated trip history with optional status and date filters.
  Future<List<TripModel>> getDriverHistory({
    String? status,
    DateTimeRange? dateRange,
    int page = 1,
    int pageSize = 10,
  });

  /// Fetches detailed trip breakdown for a specific trip ID.
  Future<TripModel> getTripDetails(int tripId);
}
