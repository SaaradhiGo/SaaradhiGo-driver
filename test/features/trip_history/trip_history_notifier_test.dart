import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip_history/domain/repositories/trip_history_repository.dart';
import 'package:saaradhigo_driver/features/trip_history/presentation/providers/trip_history_providers.dart';

class StubTripHistoryRepository implements TripHistoryRepository {
  bool shouldThrow = false;
  List<TripModel> tripsToReturn = [
    const TripModel(id: 1, status: TripStatus.completed, riderName: 'Rider 1'),
    const TripModel(id: 2, status: TripStatus.cancelled, riderName: 'Rider 2'),
  ];
  TripModel detailsToReturn = const TripModel(
    id: 1,
    status: TripStatus.completed,
  );

  String? lastStatus;
  DateTimeRange? lastDateRange;
  int lastPage = 1;

  @override
  Future<List<TripModel>> getDriverHistory({
    String? status,
    DateTimeRange? dateRange,
    int page = 1,
    int pageSize = 10,
  }) async {
    if (shouldThrow) {
      throw Exception('Network connection failed');
    }
    lastStatus = status;
    lastDateRange = dateRange;
    lastPage = page;
    return tripsToReturn;
  }

  @override
  Future<TripModel> getTripDetails(int tripId) async {
    if (shouldThrow) {
      throw Exception('Server error');
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

  test('initial state and successful fetch', () async {
    final notifier = container.read(tripHistoryNotifierProvider.notifier);

    // Allow the microtask from build() to execute
    await notifier.fetchTrips();

    final state = container.read(tripHistoryNotifierProvider);
    expect(state.status, equals(TripHistoryStatus.success));
    expect(state.trips.length, equals(2));
    expect(state.hasError, isFalse);
    expect(state.isEmpty, isFalse);
  });

  test('empty fetch transitions to empty state', () async {
    stubRepository.tripsToReturn = [];
    final notifier = container.read(tripHistoryNotifierProvider.notifier);

    await notifier.fetchTrips();

    final state = container.read(tripHistoryNotifierProvider);
    expect(state.status, equals(TripHistoryStatus.empty));
    expect(state.trips, isEmpty);
    expect(state.isEmpty, isTrue);
  });

  test(
    'error fetch transitions to error state with friendly message',
    () async {
      stubRepository.shouldThrow = true;
      final notifier = container.read(tripHistoryNotifierProvider.notifier);

      await notifier.fetchTrips();

      final state = container.read(tripHistoryNotifierProvider);
      expect(state.status, equals(TripHistoryStatus.error));
      expect(state.hasError, isTrue);
      expect(state.errorMessage, contains('Failed to load trip history'));
    },
  );

  test('setFilter updates filter and triggers refetch', () async {
    final notifier = container.read(tripHistoryNotifierProvider.notifier);

    notifier.setFilter(TripHistoryFilter.completed);

    // Wait for the async fetch triggered by setFilter
    await Future<void>.delayed(Duration.zero);

    final state = container.read(tripHistoryNotifierProvider);
    expect(state.filter, equals(TripHistoryFilter.completed));
    expect(stubRepository.lastStatus, equals('completed'));
  });

  test('setDatePreset updates datePreset and triggers refetch', () async {
    final notifier = container.read(tripHistoryNotifierProvider.notifier);

    notifier.setDatePreset(DateFilterPreset.thisMonth);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(tripHistoryNotifierProvider);
    expect(state.datePreset, equals(DateFilterPreset.thisMonth));
    expect(stubRepository.lastDateRange, isNotNull);
  });

  test('clearFilters resets to All Time and All filter', () async {
    final notifier = container.read(tripHistoryNotifierProvider.notifier);

    notifier.setFilter(TripHistoryFilter.cancelled);
    notifier.setDatePreset(DateFilterPreset.today);

    notifier.clearFilters();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(tripHistoryNotifierProvider);
    expect(state.filter, equals(TripHistoryFilter.all));
    expect(state.datePreset, equals(DateFilterPreset.allTime));
    expect(state.customDateRange, isNull);
  });

  test('loadMore appends more trips and increments currentPage', () async {
    // Return 10 trips to indicate hasMore = true
    stubRepository.tripsToReturn = List.generate(
      10,
      (i) => TripModel(id: i + 1, status: TripStatus.completed),
    );

    final notifier = container.read(tripHistoryNotifierProvider.notifier);
    await notifier.fetchTrips();

    var state = container.read(tripHistoryNotifierProvider);
    expect(state.trips.length, equals(10));
    expect(state.hasMore, isTrue);
    expect(state.currentPage, equals(1));

    // Next page returns 5 more trips
    stubRepository.tripsToReturn = List.generate(
      5,
      (i) => TripModel(id: i + 11, status: TripStatus.completed),
    );

    await notifier.loadMore();

    state = container.read(tripHistoryNotifierProvider);
    expect(state.trips.length, equals(15));
    expect(state.currentPage, equals(2));
    expect(state.hasMore, isFalse); // < 10 trips returned
  });

  test('refresh flag marks status as refreshing', () async {
    final notifier = container.read(tripHistoryNotifierProvider.notifier);
    await notifier.fetchTrips();

    final future = notifier.fetchTrips(refresh: true);
    // While in flight
    expect(
      container.read(tripHistoryNotifierProvider).status,
      equals(TripHistoryStatus.refreshing),
    );

    await future;
    expect(
      container.read(tripHistoryNotifierProvider).status,
      equals(TripHistoryStatus.success),
    );
  });
}
