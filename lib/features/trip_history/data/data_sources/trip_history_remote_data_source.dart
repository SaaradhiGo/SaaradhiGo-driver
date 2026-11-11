import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../domain/models/trip_model.dart';

import '../../../../core/utils/app_logger.dart';

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
    if (responseData is Map) {
      final rawData =
          responseData['data'] ?? responseData['trip'] ?? responseData;
      if (rawData is Map) {
        if (rawData['trip'] is Map) {
          return Map<String, dynamic>.from(rawData['trip'] as Map);
        }
        return Map<String, dynamic>.from(rawData);
      }
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is Map) {
      final data = responseData['data'];
      if (data is Map && data.containsKey('results')) {
        return (data['results'] as List?) ?? [];
      }
      if (data is List) {
        return data;
      }
      if (responseData.containsKey('results')) {
        return (responseData['results'] as List?) ?? [];
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
        .whereType<Map>()
        .map((raw) {
          try {
            final trip = TripModel.fromJson(Map<String, dynamic>.from(raw));
            if (trip.id <= 0) return null;
            return trip;
          } catch (e, st) {
            AppLogger.e('Failed to parse trip item: $raw', e, st);
            return null;
          }
        })
        .whereType<TripModel>()
        .toList();
  }

  @override
  Future<TripModel> getTripDetails(int tripId) async {
    final response = await dio.get(ApiEndpoints.tripDetails(tripId.toString()));
    final data = _extractData(response.data);
    return TripModel.fromJson(data);
  }
}
