import 'package:flutter/material.dart';

import '../../../../domain/models/trip_model.dart';
import '../../domain/repositories/trip_history_repository.dart';
import '../data_sources/trip_history_remote_data_source.dart';

class TripHistoryRepositoryImpl implements TripHistoryRepository {
  final TripHistoryRemoteDataSource remoteDataSource;

  TripHistoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<TripModel>> getDriverHistory({
    String? status,
    DateTimeRange? dateRange,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await remoteDataSource.getDriverHistory(
      status: status,
      dateRange: dateRange,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<TripModel> getTripDetails(int tripId) async {
    return await remoteDataSource.getTripDetails(tripId);
  }
}
