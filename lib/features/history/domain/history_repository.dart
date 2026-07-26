import '../../trip/domain/trip.dart';

abstract class HistoryRepository {
  /// `GET /ride/driver-history/` — completed and cancelled trips, newest
  /// first. [status] filters server-side when provided.
  Future<List<Trip>> fetchHistory({
    int page = 1,
    int pageSize = 20,
    String? status,
  });
}
