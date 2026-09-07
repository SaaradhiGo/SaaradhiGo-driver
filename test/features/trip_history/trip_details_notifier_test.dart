import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip_history/domain/repositories/trip_history_repository.dart';
import 'package:saaradhigo_driver/features/trip_history/presentation/providers/trip_history_providers.dart';

class StubTripHistoryRepository implements TripHistoryRepository {
  bool shouldThrow = false;
  TripModel detailsToReturn = const TripModel(
    id: 101,
    status: TripStatus.completed,
    riderName: 'Ananya S.',
    finalFare: '480',
    riderRating: 4.9,
  );

  @override
  Future<List<TripModel>> getDriverHistory({
    String? status,
    dynamic dateRange,
    int page = 1,
    int pageSize = 10,
  }) async {
    return [];
  }

  @override
  Future<TripModel> getTripDetails(int tripId) async {
    if (shouldThrow) {
      throw Exception('Failed to load trip');
    }
    return detailsToReturn;
  }
}

void main() {
  late StubTripHistoryRepository stubRepository;
  late ProviderContainer container;

  setUp(() {
    stubRepository = StubTripHistoryRepository();
    container = ProviderContainer(
      overrides: [
        tripHistoryRepositoryProvider.overrideWithValue(stubRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('TripDetailsNotifier fetches and populates trip details', () async {
    final notifier = container.read(tripDetailsNotifierProvider.notifier);
    await notifier.loadTrip(101);

    final state = container.read(tripDetailsNotifierProvider);
    expect(state.status, equals(TripDetailsStatus.success));
    expect(state.trip, isNotNull);
    expect(state.trip!.id, equals(101));
    expect(state.trip!.riderName, equals('Ananya S.'));
    expect(state.trip!.finalFare, equals('480'));
    expect(state.trip!.riderRating, equals(4.9));
  });

  test('TripDetailsNotifier handles error on failure', () async {
    stubRepository.shouldThrow = true;

    final notifier = container.read(tripDetailsNotifierProvider.notifier);
    await notifier.loadTrip(101);

    final state = container.read(tripDetailsNotifierProvider);
    expect(state.status, equals(TripDetailsStatus.error));
    expect(state.trip, isNull);
    expect(state.errorMessage, isNotNull);
  });
}
