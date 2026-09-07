import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../domain/models/trip_model.dart';

abstract class TripHistoryRemoteDataSource {
  Future<List<TripModel>> getDriverHistory({
    String? status,
    DateTimeRange? dateRange,
    int page = 1,
    int pageSize = 10,
  });

  Future<TripModel> getTripDetails(int tripId);
}

class TripHistoryRemoteDataSourceImpl implements TripHistoryRemoteDataSource {
  final Dio dio;

  TripHistoryRemoteDataSourceImpl(this.dio);

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic> &&
        responseData.containsKey('data') &&
        responseData['data'] != null) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'] as List<dynamic>? ?? [];
      }
      if (data is List) {
        return data;
      }
      if (responseData.containsKey('results')) {
        return responseData['results'] as List<dynamic>? ?? [];
      }
    }
    if (responseData is List) {
      return responseData;
    }
    return [];
  }

  @override
  Future<List<TripModel>> getDriverHistory({
    String? status,
    DateTimeRange? dateRange,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'page_size': pageSize};

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }

    if (dateRange != null) {
      queryParams['start_date'] = dateRange.start.toIso8601String().split(
        'T',
      )[0];
      queryParams['end_date'] = dateRange.end.toIso8601String().split('T')[0];
    }

    final response = await dio.get(
      ApiEndpoints.tripHistory,
      queryParameters: queryParams,
    );

    final rawList = _extractList(response.data);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((json) => TripModel.fromJson(json))
        .toList();
  }

  @override
  Future<TripModel> getTripDetails(int tripId) async {
    final response = await dio.get(ApiEndpoints.tripDetails(tripId.toString()));
    final data = _extractData(response.data);
    return TripModel.fromJson(data);
  }
}
