import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip_history/domain/repositories/trip_history_repository.dart';
import 'package:saaradhigo_driver/features/trip_history/presentation/providers/trip_history_providers.dart';

class StubTripHistoryRepository implements TripHistoryRepository {
  List<TripModel> tripsToReturn = [];
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
    lastStatus = status;
    lastDateRange = dateRange;
    lastPage = page;
    return tripsToReturn;
  }

  @override
  Future<TripModel> getTripDetails(int tripId) async {
    throw UnimplementedError();
  }
}

TripModel _trip(int id, String? createdAt) =>
    TripModel(id: id, status: TripStatus.completed, createdAt: createdAt);

/// Lets the async fetch triggered by a notifier setter complete.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

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

  test('Today preset keeps only trips from today (client-side fallback)', () async {
    final now = DateTime.now();
    stubRepository.tripsToReturn = [
      _trip(1, now.toIso8601String()),
      _trip(2, now.subtract(const Duration(days: 3)).toIso8601String()),
    ];

    final notifier = container.read(tripHistoryNotifierProvider.notifier);
    notifier.setDatePreset(DateFilterPreset.today);
    await _settle();

    final state = container.read(tripHistoryNotifierProvider);
    expect(state.datePreset, equals(DateFilterPreset.today));
    expect(state.trips.map((t) => t.id).toList(), equals([1]));
    // Normalized today range reaches the repository.
    final range = stubRepository.lastDateRange!;
    expect(range.start, equals(DateTime(now.year, now.month, now.day)));
    expect(
      range.end,
      equals(DateTime(now.year, now.month, now.day, 23, 59, 59, 999)),
    );
  });

  test('This Week preset drops trips before the week start', () async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    stubRepository.tripsToReturn = [
      _trip(1, weekStart.add(const Duration(hours: 1)).toIso8601String()),
      _trip(
        2,
        weekStart
            .subtract(const Duration(days: 1, hours: 12))
            .toIso8601String(),
      ),
    ];

    final notifier = container.read(tripHistoryNotifierProvider.notifier);
    notifier.setDatePreset(DateFilterPreset.thisWeek);
    await _settle();

    final state = container.read(tripHistoryNotifierProvider);
    expect(state.trips.map((t) => t.id).toList(), equals([1]));
  });

  test('custom range includes trips on the selected end day', () async {
    stubRepository.tripsToReturn = [
      _trip(1, '2026-09-04T23:00:00'),
      _trip(2, '2026-09-05T00:30:00'),
    ];

    final notifier = container.read(tripHistoryNotifierProvider.notifier);
    notifier.setDatePreset(
      DateFilterPreset.custom,
      customRange: DateTimeRange(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 4), // picker-style end at 00:00:00
      ),
    );
    await _settle();

    final state = container.read(tripHistoryNotifierProvider);
    expect(state.datePreset, equals(DateFilterPreset.custom));
    expect(state.trips.map((t) => t.id).toList(), equals([1]));
    // effectiveDateRange normalized the picker end before the repo call.
    final range = stubRepository.lastDateRange!;
    expect(range.end.hour, equals(23));
    expect(range.end.minute, equals(59));
    expect(range.end.second, equals(59));
    expect(range.end.millisecond, equals(999));
  });

  test('custom range drops trips before the start day', () async {
    stubRepository.tripsToReturn = [
      _trip(1, '2026-09-04T10:00:00'),
      _trip(2, '2026-08-31T23:59:59'),
    ];

    final notifier = container.read(tripHistoryNotifierProvider.notifier);
    notifier.setDatePreset(
      DateFilterPreset.custom,
      customRange: DateTimeRange(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 4),
      ),
    );
    await _settle();

    final state = container.read(tripHistoryNotifierProvider);
    expect(state.trips.map((t) => t.id).toList(), equals([1]));
  });

  test('loadMore keeps the active date filter and raw-length hasMore', () async {
    final now = DateTime.now();
    final oldDay = now.subtract(const Duration(days: 10)).toIso8601String();
    stubRepository.tripsToReturn = [
      ...List.generate(6, (i) => _trip(i + 1, oldDay)),
      ...List.generate(4, (i) => _trip(i + 7, now.toIso8601String())),
    ];

    final notifier = container.read(tripHistoryNotifierProvider.notifier);
    notifier.setDatePreset(DateFilterPreset.today);
    await _settle();

    var state = container.read(tripHistoryNotifierProvider);
    expect(state.trips.length, equals(4));
    expect(state.hasMore, isTrue); // raw page was full (10)

    // Page 2 returns a full page of out-of-range trips.
    stubRepository.tripsToReturn =
        List.generate(10, (i) => _trip(i + 11, oldDay));
    await notifier.loadMore();

    state = container.read(tripHistoryNotifierProvider);
    expect(state.currentPage, equals(2));
    expect(state.trips.length, equals(4)); // nothing in-range appended
    expect(state.hasMore, isTrue); // raw page 2 was full — keep streaming
  });

  test('filtered-empty transitions to empty; clearFilters resets', () async {
    final now = DateTime.now();
    stubRepository.tripsToReturn = [
      _trip(1, now.subtract(const Duration(days: 10)).toIso8601String()),
      _trip(2, now.subtract(const Duration(days: 10)).toIso8601String()),
    ];

    final notifier = container.read(tripHistoryNotifierProvider.notifier);
    notifier.setDatePreset(DateFilterPreset.today);
    await _settle();

    var state = container.read(tripHistoryNotifierProvider);
    expect(state.status, equals(TripHistoryStatus.empty));
    expect(state.isEmpty, isTrue);
    expect(state.trips, isEmpty);

    notifier.clearFilters();
    await _settle();

    state = container.read(tripHistoryNotifierProvider);
    expect(state.datePreset, equals(DateFilterPreset.allTime));
    expect(state.filter, equals(TripHistoryFilter.all));
    expect(state.status, equals(TripHistoryStatus.success));
    expect(state.trips.length, equals(2)); // All Time keeps everything
  });

  test('unparseable createdAt dropped when filtered, kept under All Time', () async {
    final now = DateTime.now();
    stubRepository.tripsToReturn = [
      _trip(1, now.toIso8601String()),
      _trip(2, 'garbage-timestamp'),
    ];

    final notifier = container.read(tripHistoryNotifierProvider.notifier);
    notifier.setDatePreset(DateFilterPreset.today);
    await _settle();

    var state = container.read(tripHistoryNotifierProvider);
    expect(state.trips.map((t) => t.id).toList(), equals([1]));

    notifier.clearFilters();
    await _settle();

    state = container.read(tripHistoryNotifierProvider);
    expect(state.trips.map((t) => t.id).toList(), equals([1, 2]));
  });
}