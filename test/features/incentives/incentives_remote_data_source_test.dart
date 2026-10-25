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
    dio = Dio(BaseOptions(baseUrl: 'https://dev.api.saaradhigo.com/'));
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
      'getIncentives makes exactly ONE request, to the real route',
      () async {
        // This used to try '/driver/incentives/' and retry
        // '/driver/driver/incentives/' on 404. The single-segment path never
        // existed -- servers/driver/urls.py is included at /driver/ and
        // declares path('driver/incentives/') -- so every read cost a
        // guaranteed 404 before the call that worked.
        int attempts = 0;
        adapter.handler = (options) async {
          attempts++;
          expect(options.path, equals(ApiEndpoints.driverIncentives));
          expect(options.path, equals('/driver/driver/incentives/'));
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
        };

        final results = await dataSource.getIncentives();
        expect(results.length, equals(1));
        expect(results.first.id, equals(202));
        expect(
          attempts,
          equals(1),
          reason: 'a second request means the 404 retry is back',
        );
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
      'getEliteStatus makes exactly ONE request, to the real route',
      () async {
        int attempts = 0;
        adapter.handler = (options) async {
          attempts++;
          expect(options.path, equals(ApiEndpoints.driverEliteStatus));
          expect(options.path, equals('/driver/driver/elite-status/'));
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
        };

        final status = await dataSource.getEliteStatus();
        expect(status.tier, equals('Silver'));
        expect(status.totalTrips, equals(25));
        expect(
          attempts,
          equals(1),
          reason: 'a second request means the 404 retry is back',
        );
      },
    );
  });
}
