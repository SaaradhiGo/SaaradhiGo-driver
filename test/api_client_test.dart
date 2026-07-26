import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_client.dart';
import 'package:saaradhigo_driver/core/network/api_exception.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeHttpAdapter adapter;
  late FakeTokenStore tokens;
  late ApiClient client;

  ApiClient buildClient({void Function()? onExpired}) {
    final dio = Dio()..httpClientAdapter = adapter;
    return ApiClient(tokens, dio: dio, onSessionExpired: onExpired);
  }

  setUp(() {
    adapter = FakeHttpAdapter();
    tokens = FakeTokenStore(access: 'access-1', refresh: 'refresh-1');
    client = buildClient();
  });

  group('envelope unwrapping', () {
    test('unwraps {status, data} into the payload', () async {
      adapter.enqueue(body: {
        'status': 'success',
        'data': {'id': 4, 'approved': true},
      });

      final result = await client.get('/driver/driver/profile/');

      expect(result['id'], 4);
      expect(result['approved'], true);
    });

    test('passes a bare (unenveloped) body straight through', () async {
      adapter.enqueue(body: {'count': 2, 'results': []});

      final result = await client.get('/driver/earnings/');

      expect(result['count'], 2);
    });

    test('pulls results out of a DRF paginated envelope', () async {
      adapter.enqueue(body: {
        'status': 'success',
        'data': {
          'count': 1,
          'results': [
            {'id': 1, 'amount': '120.00'},
          ],
        },
      });

      final list = await client.getList('/driver/earnings/');

      expect(list, hasLength(1));
      expect((list.first as Map)['amount'], '120.00');
    });
  });

  group('authentication', () {
    test('attaches the bearer token', () async {
      adapter.enqueue(body: {'data': <String, dynamic>{}});

      await client.get('/driver/driver/profile/');

      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer access-1',
      );
    });

    test('does not attach a token to auth routes', () async {
      adapter.enqueue(body: {'data': <String, dynamic>{}});

      await client.post('/auth/otp/', body: {}, skipAuth: true);

      expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('refreshes once on 401 and replays the original request', () async {
      // 1st: the protected call is rejected.
      adapter.enqueue(status: 401, body: {
        'status': 'error',
        'error': {'code': 'TOKEN_EXPIRED', 'message': 'expired'},
      });
      // 2nd: the refresh succeeds.
      adapter.enqueue(body: {
        'status': 'success',
        'data': {'access': 'access-2', 'refresh': 'refresh-2'},
      });
      // 3rd: the replayed call succeeds.
      adapter.enqueue(body: {
        'status': 'success',
        'data': {'id': 4},
      });

      final result = await client.get('/driver/driver/profile/');

      expect(result['id'], 4);
      expect(tokens.access, 'access-2', reason: 'new token must be persisted');
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer access-2',
        reason: 'the replay must carry the refreshed token',
      );
    });

    test('signals session-expired when the refresh token is spent', () async {
      var expiredCalls = 0;
      client = buildClient(onExpired: () => expiredCalls++);

      adapter.enqueue(status: 401, body: {'error': <String, dynamic>{}});
      adapter.enqueue(status: 401, body: {'error': <String, dynamic>{}});

      await expectLater(
        client.get('/driver/driver/profile/'),
        throwsA(isA<ApiException>()),
      );

      expect(expiredCalls, 1);
      expect(tokens.cleared, isTrue,
          reason: 'a spent refresh token must not be kept on the device');
    });

    test('does not retry a request more than once', () async {
      client = buildClient();
      // Every call 401s, including the replay.
      adapter.enqueue(status: 401, body: {'error': <String, dynamic>{}});
      adapter.enqueue(body: {
        'status': 'success',
        'data': {'access': 'access-2'},
      });
      adapter.enqueue(status: 401, body: {'error': <String, dynamic>{}});

      await expectLater(
        client.get('/driver/driver/profile/'),
        throwsA(isA<ApiException>()),
      );

      // original + refresh + one replay, and no infinite loop
      expect(adapter.requests.length, 3);
    });
  });

  group('error translation', () {
    test('surfaces the server message and code', () async {
      adapter.enqueue(status: 400, body: {
        'status': 'error',
        'error': {
          'code': 'INSUFFICIENT_BALANCE',
          'message': 'Minimum withdrawal amount is ₹500',
        },
      });

      try {
        await client.post('/driver/withdrawals/request/', body: {});
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.code, 'INSUFFICIENT_BALANCE');
        expect(e.message, contains('Minimum withdrawal'));
        expect(e.statusCode, 400);
      }
    });

    test('marks connection failures as network errors', () async {
      final dio = Dio()
        ..httpClientAdapter = _ThrowingAdapter(DioExceptionType.connectionError);
      client = ApiClient(tokens, dio: dio);

      try {
        await client.get('/driver/driver/profile/');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.isNetwork, isTrue);
        expect(e.message, contains('No connection'));
      }
    });

    test('gives a rate-limit message for 429', () async {
      adapter.enqueue(status: 429, body: <String, dynamic>{});

      try {
        await client.post('/auth/otp/', body: {}, skipAuth: true);
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.isRateLimited, isTrue);
        expect(e.message, contains('Too many attempts'));
      }
    });
  });
}

class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.type);

  final DioExceptionType type;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(requestOptions: options, type: type);
  }

  @override
  void close({bool force = false}) {}
}
