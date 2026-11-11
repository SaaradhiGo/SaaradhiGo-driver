import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip_history/data/data_sources/trip_history_remote_data_source.dart';
import 'package:saaradhigo_driver/features/trip_history/data/repositories/trip_history_repository_impl.dart';

class FakeTripHistoryRemoteDataSource implements TripHistoryRemoteDataSource {
  List<TripModel> historyToReturn = [
    const TripModel(
      id: 1,
      status: TripStatus.completed,
      riderName: 'Test Rider',
      finalFare: '300',
    ),
  ];

  TripModel detailsToReturn = const TripModel(
    id: 1,
    status: TripStatus.completed,
    riderName: 'Test Rider',
    finalFare: '300',
    pickupAddress: 'Pickup',
    destinationAddress: 'Destination',
  );

  String? lastStatus;
  DateTimeRange? lastDateRange;
  int? lastPage;
  int? lastPageSize;
  int? lastTripId;

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
    lastPageSize = pageSize;
    return historyToReturn;
  }

  @override
  Future<TripModel> getTripDetails(int tripId) async {
    lastTripId = tripId;
    return detailsToReturn;
  }
}

void main() {
  late FakeTripHistoryRemoteDataSource fakeDataSource;
  late TripHistoryRepositoryImpl repository;

  setUp(() {
    fakeDataSource = FakeTripHistoryRemoteDataSource();
    repository = TripHistoryRepositoryImpl(fakeDataSource);
  });

  test(
    'getDriverHistory delegates to remoteDataSource with correct arguments',
    () async {
      final range = DateTimeRange(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 4),
      );

      final result = await repository.getDriverHistory(
        status: 'completed',
        dateRange: range,
        page: 3,
        pageSize: 20,
      );

      expect(result.length, equals(1));
      expect(fakeDataSource.lastStatus, equals('completed'));
      expect(fakeDataSource.lastDateRange, equals(range));
      expect(fakeDataSource.lastPage, equals(3));
      expect(fakeDataSource.lastPageSize, equals(20));
    },
  );

  test('getTripDetails delegates to remoteDataSource with tripId', () async {
    final result = await repository.getTripDetails(42);

    expect(result.id, equals(1));
    expect(fakeDataSource.lastTripId, equals(42));
  });
}
