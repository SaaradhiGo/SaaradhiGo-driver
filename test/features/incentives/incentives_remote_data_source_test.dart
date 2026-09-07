import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/features/incentives/data/data_sources/incentives_remote_data_source.dart';

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
  late IncentivesRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://dev.api.saaradhigo.in/'));
    adapter = _StubHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    dataSource = IncentivesRemoteDataSourceImpl(dio);
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

  group('IncentivesRemoteDataSource', () {
    test('getIncentives fetches list of quests from canonical path', () async {
      adapter.handler = (options) async {
        expect(options.path, equals(ApiEndpoints.driverIncentives));
        return jsonResponse({
          'status': 'success',
          'data': [
            {
              'id': 101,
              'title': 'Weekend Quest',
              'description': 'Complete 10 trips between Fri and Sun',
              'target_trips': 10,
              'progress_trips': 7,
              'reward_amount': '500.00',
              'is_completed': false,
              'type': 'weekend_quest',
            },
          ],
        });
      };

      final results = await dataSource.getIncentives();
      expect(results.length, equals(1));
      expect(results.first.id, equals(101));
      expect(results.first.title, equals('Weekend Quest'));
      expect(results.first.targetTrips, equals(10));
      expect(results.first.progressTrips, equals(7));
      expect(results.first.rewardAmount, equals('500.00'));
      expect(results.first.remainingTrips, equals(3));
      expect(results.first.progressFraction, closeTo(0.7, 0.01));
    });

    test(
      'getIncentives falls back to driverIncentivesFallback on 404',
      () async {
        int attempt = 0;
        adapter.handler = (options) async {
          attempt++;
          if (attempt == 1) {
            expect(options.path, equals(ApiEndpoints.driverIncentives));
            return jsonResponse({'detail': 'Not found'}, statusCode: 404);
          } else {
            expect(options.path, equals(ApiEndpoints.driverIncentivesFallback));
            return jsonResponse({
              'status': 'success',
              'data': [
                {
                  'id': 202,
                  'title': 'Peak Hour Boost',
                  'target_trips': 5,
                  'progress_trips': 2,
                  'reward_amount': '250.00',
                },
              ],
            });
          }
        };

        final results = await dataSource.getIncentives();
        expect(results.length, equals(1));
        expect(results.first.id, equals(202));
        expect(attempt, equals(2));
      },
    );

    test('getEliteStatus fetches elite metrics from canonical path', () async {
      adapter.handler = (options) async {
        expect(options.path, equals(ApiEndpoints.driverEliteStatus));
        return jsonResponse({
          'status': 'success',
          'data': {
            'tier': 'Gold',
            'total_trips': 120,
            'rating': '4.85',
            'acceptance_rate': '98%',
            'cancellation_rate': '1%',
            'next_tier': 'Platinum',
            'trips_to_next_tier': 80,
          },
        });
      };

      final status = await dataSource.getEliteStatus();
      expect(status.tier, equals('Gold'));
      expect(status.totalTrips, equals(120));
      expect(status.rating, equals('4.85'));
      expect(status.acceptanceRate, equals('98%'));
      expect(status.cancellationRate, equals('1%'));
      expect(status.nextTier, equals('Platinum'));
      expect(status.isRatingQualified, isTrue);
      expect(status.isAcceptanceQualified, isTrue);
      expect(status.isCancellationQualified, isTrue);
    });

    test(
      'getEliteStatus falls back to driverEliteStatusFallback on 404',
      () async {
        int attempt = 0;
        adapter.handler = (options) async {
          attempt++;
          if (attempt == 1) {
            expect(options.path, equals(ApiEndpoints.driverEliteStatus));
            return jsonResponse({'detail': 'Not found'}, statusCode: 404);
          } else {
            expect(
              options.path,
              equals(ApiEndpoints.driverEliteStatusFallback),
            );
            return jsonResponse({
              'status': 'success',
              'data': {
                'tier': 'Silver',
                'total_trips': 25,
                'rating': '4.9',
                'acceptance_rate': '100%',
                'cancellation_rate': '0%',
              },
            });
          }
        };

        final status = await dataSource.getEliteStatus();
        expect(status.tier, equals('Silver'));
        expect(status.totalTrips, equals(25));
        expect(attempt, equals(2));
      },
    );
  });
}
