/// A driver can now rate the passenger on a completed trip.
///
/// `/ride/rate-trip/` is symmetric -- drivers rate riders as riders rate
/// drivers, one rating per user per trip, and the server recomputes the rated
/// user's average. **Neither app could submit one**, so every average sat at
/// its default.
///
/// For a driver this is the only record that a passenger was abusive or kept
/// them waiting, which is the input an operator needs before they can act on
/// a pattern.
///
/// The server's refusals are kept apart rather than flattened, because they
/// mean different things:
///   ALREADY_RATED (409)      -> done; stop offering it
///   TRIP_NOT_COMPLETED (400) -> the trip has not finished
///   FORBIDDEN (403)          -> not this driver's trip
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/features/trip/data/data_sources/rating_remote_data_source.dart';

class _StubAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int statusCode = 201;
  Map<String, dynamic> body = const {
    'status': 'success',
    'data': {'rating_id': 77, 'trip_id': 991, 'score': 5},
  };
  bool throwTransport = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (throwTransport) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'no network',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _StubAdapter adapter;
  late RatingRemoteDataSourceImpl source;

  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://dev.api.saaradhigo.in/',
        // Without this, Dio throws for any non-2xx before the data source can
        // read the body -- and the refusal codes are the whole point here.
        validateStatus: (_) => true,
      ),
    );
    adapter = _StubAdapter();
    dio.httpClientAdapter = adapter;
    source = RatingRemoteDataSourceImpl(dio);
  });

  Map<String, dynamic> sentBody() =>
      (adapter.requests.single.data as Map).cast<String, dynamic>();

  group('submitting', () {
    test('posts the trip and score to the real route', () async {
      final result = await source.rateTrip(tripId: 991, score: 5);

      expect(result.isSubmitted, isTrue);
      expect(result.ratingId, 77);
      expect(adapter.requests.single.path, ApiEndpoints.rateTrip);
      expect(adapter.requests.single.path, '/ride/rate-trip/');
      expect(sentBody(), {'trip_id': 991, 'score': 5});
    });

    test('a comment is included only when there is one', () async {
      await source.rateTrip(
        tripId: 991,
        score: 4,
        comments: '  Kept me waiting  ',
      );
      expect(sentBody()['comments'], 'Kept me waiting');

      adapter.requests.clear();
      await source.rateTrip(tripId: 991, score: 4, comments: '   ');
      expect(sentBody().containsKey('comments'), isFalse);
    });

    test('a score outside 1-5 never reaches the server', () async {
      for (final score in [0, 6, -3, 10]) {
        final result = await source.rateTrip(tripId: 991, score: score);
        expect(result.isSubmitted, isFalse);
      }
      expect(adapter.requests, isEmpty);
    });
  });

  group('the refusals keep their meaning', () {
    void refuse(String code, String message, int status) {
      adapter.statusCode = status;
      adapter.body = {
        'status': 'error',
        'error': {'code': code, 'message': message},
      };
    }

    test('ALREADY_RATED is settled, not an error to show', () async {
      refuse('ALREADY_RATED', 'You have already rated this trip', 409);

      final result = await source.rateTrip(tripId: 991, score: 5);

      expect(result.outcome, RatingOutcome.alreadyRated);
      expect(
        result.isSettled,
        isTrue,
        reason: 'the rating exists, so stop offering it',
      );
    });

    test('TRIP_NOT_COMPLETED keeps the server own words', () async {
      refuse('TRIP_NOT_COMPLETED', 'You can only rate a completed trip', 400);

      final result = await source.rateTrip(tripId: 991, score: 5);

      expect(result.outcome, RatingOutcome.notEligible);
      expect(result.message, 'You can only rate a completed trip');
      expect(result.isSettled, isFalse);
    });

    test('FORBIDDEN is not eligible', () async {
      refuse('FORBIDDEN', 'You were not the driver on this trip', 403);

      expect(
        (await source.rateTrip(tripId: 991, score: 5)).outcome,
        RatingOutcome.notEligible,
      );
    });

    test('a transport failure says the rating was not saved', () async {
      adapter.throwTransport = true;

      final result = await source.rateTrip(tripId: 991, score: 5);

      expect(result.outcome, RatingOutcome.failed);
      expect(
        result.message,
        contains('not saved'),
        reason:
            'a driver must not believe a rating was recorded when it '
            'was not',
      );
    });

    test('an unexpected status is a failure carrying its code', () async {
      adapter.statusCode = 500;
      adapter.body = {'status': 'error'};

      final result = await source.rateTrip(tripId: 991, score: 5);

      expect(result.outcome, RatingOutcome.failed);
      expect(result.message, contains('500'));
    });

    test(
      'a refusal is classified the same way when Dio THROWS for it',
      () async {
        // Production DioClient uses Dio's default validateStatus, so a non-2xx
        // arrives as a DioException rather than a response. Both paths have to
        // reach the same conclusion, or the behaviour would depend on
        // configuration this data source does not own.
        final throwingDio = Dio(BaseOptions(baseUrl: 'https://x/'));
        final throwingAdapter = _StubAdapter()
          ..statusCode = 409
          ..body = {
            'status': 'error',
            'error': {'code': 'ALREADY_RATED', 'message': 'Already rated'},
          };
        throwingDio.httpClientAdapter = throwingAdapter;

        final result = await RatingRemoteDataSourceImpl(
          throwingDio,
        ).rateTrip(tripId: 991, score: 5);

        expect(result.outcome, RatingOutcome.alreadyRated);
        expect(result.isSettled, isTrue);
      },
    );

    test('nothing throws out of this data source', () async {
      // It is called from a bottom sheet on the post-trip screen; an
      // unhandled throw there would strand a driver on a dead screen with
      // the next ride waiting.
      adapter.statusCode = 418;
      adapter.body = {'unexpected': 'shape'};

      await expectLater(source.rateTrip(tripId: 991, score: 3), completes);
    });
  });
}
