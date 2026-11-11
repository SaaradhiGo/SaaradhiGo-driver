import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip/data/data_sources/trip_remote_data_source.dart';

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
  late TripRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.saaradhigo.test/api/v1'));
    adapter = _StubHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    dataSource = TripRemoteDataSourceImpl(dio);
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

  group('TripRemoteDataSource - getActiveTrip', () {
    test(
      'returns active trip with DRF Decimal string fields successfully',
      () async {
        adapter.handler = (options) async {
          expect(options.path, equals(ApiEndpoints.activeTrip));
          return jsonResponse({
            'status': 'success',
            'data': {
              'id': 101,
              'status': 'in_progress',
              'pickup_address': 'Ameerpet Metro',
              'destination_address': 'Hitech City',
              'pickup_lat': '17.385000',
              'pickup_long': '78.486700',
              'destination_lat': '17.440000',
              'destination_long': '78.348000',
              'estimated_distance_km': '10.50',
              'actual_distance_km': '10.50',
              'estimated_duration_min': '25.00',
              'actual_duration_min': '24.00',
              'user': 'Raja Kumar',
            },
          });
        };

        final trip = await dataSource.getActiveTrip();

        expect(trip, isNotNull);
        expect(trip!.id, equals(101));
        expect(trip.status, equals(TripStatus.inProgress));
        expect(trip.riderName, equals('Raja Kumar'));
        expect(trip.pickupLat, equals(17.385));
        expect(trip.distanceKm, equals(10.5));
      },
    );

    test('returns null gracefully on 404 NO_ACTIVE_TRIP', () async {
      adapter.handler = (options) async {
        return jsonResponse({
          'code': 'NO_ACTIVE_TRIP',
          'message': 'No active trip found',
        }, statusCode: 404);
      };

      final trip = await dataSource.getActiveTrip();
      expect(trip, isNull);
    });

    test('returns null when payload has no trip id', () async {
      adapter.handler = (options) async {
        return jsonResponse({'status': 'success', 'data': {}});
      };

      final trip = await dataSource.getActiveTrip();
      expect(trip, isNull);
    });
  });
}
