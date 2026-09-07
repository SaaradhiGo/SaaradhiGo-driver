import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip_history/data/data_sources/trip_history_remote_data_source.dart';

class _StubHttpClientAdapter implements HttpClientAdapter {
  late Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _StubHttpClientAdapter adapter;
  late TripHistoryRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.saaradhigo.test/api/v1'));
    adapter = _StubHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    dataSource = TripHistoryRemoteDataSourceImpl(dio);
  });

  ResponseBody jsonResponse(dynamic body, {int statusCode = 200}) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  group('TripHistoryRemoteDataSource - getDriverHistory', () {
    test('fetches trips and passes query parameters correctly', () async {
      adapter.handler = (options) async {
        expect(options.path, equals(ApiEndpoints.tripHistory));
        expect(options.queryParameters['page'], equals(2));
        expect(options.queryParameters['page_size'], equals(15));
        expect(options.queryParameters['status'], equals('completed'));
        expect(options.queryParameters['start_date'], equals('2026-09-01'));
        expect(options.queryParameters['end_date'], equals('2026-09-04'));

        return jsonResponse({
          'data': {
            'results': [
              {
                'id': 101,
                'status': 'completed',
                'user': 'Rahul Sharma',
                'final_fare': '480',
                'pickup_address': 'Taj Palace',
                'destination_address': 'BKC',
                'actual_distance_km': 8.4,
                'actual_duration_min': 22,
                'payment_method': 'digital',
              },
            ],
          },
        });
      };

      final result = await dataSource.getDriverHistory(
        status: 'completed',
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 4),
        ),
        page: 2,
        pageSize: 15,
      );

      expect(result.length, equals(1));
      expect(result.first.id, equals(101));
      expect(result.first.status, equals(TripStatus.completed));
      expect(result.first.riderName, equals('Rahul Sharma'));
      expect(result.first.finalFare, equals('480'));
    });

    test('handles raw results map without nested data object', () async {
      adapter.handler = (options) async {
        return jsonResponse({
          'results': [
            {
              'id': 102,
              'status': 'cancelled',
              'rider_name': 'Priya Desai',
              'cancellation_reason': 'Vehicle Breakdown',
            },
          ],
        });
      };

      final result = await dataSource.getDriverHistory();

      expect(result.length, equals(1));
      expect(result.first.id, equals(102));
      expect(result.first.status, equals(TripStatus.cancelled));
      expect(result.first.cancellationReason, equals('Vehicle Breakdown'));
    });

    test('returns empty list when results is empty', () async {
      adapter.handler = (options) async {
        return jsonResponse({'results': []});
      };

      final result = await dataSource.getDriverHistory();
      expect(result, isEmpty);
    });
  });

  group('TripHistoryRemoteDataSource - getTripDetails', () {
    test(
      'fetches full single trip details and parses invoice fields',
      () async {
        adapter.handler = (options) async {
          expect(options.path, equals(ApiEndpoints.tripDetails('501')));
          return jsonResponse({
            'data': {
              'id': 501,
              'status': 'completed',
              'user': 'Ananya S.',
              'estimated_fare': '560',
              'final_fare': '480',
              'pickup_address': 'Colaba',
              'destination_address': 'Bandra',
              'pickup_lat': 18.922,
              'pickup_lng': 72.834,
              'destination_lat': 19.060,
              'destination_lng': 72.865,
              'distance_km': 8.4,
              'duration_min': 24,
              'payment_method': 'digital',
              'rider_rating': 4.9,
              'fare_breakdown': {
                'base_fare': 560,
                'service_fee': -80,
                'net_earnings': 480,
              },
            },
          });
        };

        final trip = await dataSource.getTripDetails(501);

        expect(trip.id, equals(501));
        expect(trip.riderName, equals('Ananya S.'));
        expect(trip.finalFare, equals('480'));
        expect(trip.pickupLat, equals(18.922));
        expect(trip.riderRating, equals(4.9));
        expect(trip.fareBreakdown?['service_fee'], equals(-80));
      },
    );
  });
}
