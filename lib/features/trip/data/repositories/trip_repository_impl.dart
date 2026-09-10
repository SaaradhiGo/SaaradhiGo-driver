import '../../../../domain/models/trip_model.dart';
import '../../domain/repositories/trip_repository.dart';
import '../data_sources/trip_remote_data_source.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl(this._remote);

  final TripRemoteDataSource _remote;

  @override
  Future<TripModel?> getActiveTrip() => _remote.getActiveTrip();

  @override
  Future<void> driverCancel(
    int tripId, {
    required String reason,
    String? note,
  }) => _remote.driverCancel(tripId, reason: reason, note: note);
}
