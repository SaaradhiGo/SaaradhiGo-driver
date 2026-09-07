import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/trip_history_repository.dart';
import 'trip_history_providers.dart';

class TripDetailsNotifier extends Notifier<TripDetailsState> {
  late TripHistoryRepository _repository;
  int? _tripId;

  @override
  TripDetailsState build() {
    _repository = ref.watch(tripHistoryRepositoryProvider);
    ref.onDispose(() => _tripId = null);
    return const TripDetailsState();
  }

  Future<void> loadTrip(int tripId) async {
    _tripId = tripId;
    state = const TripDetailsState(status: TripDetailsStatus.loading);

    try {
      final trip = await _repository.getTripDetails(tripId);
      if (_tripId != tripId) return;
      state = TripDetailsState(status: TripDetailsStatus.success, trip: trip);
    } catch (_) {
      if (_tripId != tripId) return;
      state = const TripDetailsState(
        status: TripDetailsStatus.error,
        errorMessage: 'Failed to load trip invoice details.',
      );
    }
  }

  void retry() {
    if (_tripId != null) {
      loadTrip(_tripId!);
    }
  }
}
