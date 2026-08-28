import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/core/network/auth_interceptor.dart';
import 'package:saaradhigo_driver/core/network/auth_session_events.dart';
import 'package:saaradhigo_driver/core/network/logging_interceptor.dart';
import 'package:saaradhigo_driver/core/storage/secure_storage_service.dart';

void main() {
  const expiredAccessToken = 'expired-access-token';
  const refreshToken = 'valid-refresh-token';
  const refreshedAccessToken = 'refreshed-access-token';
  const rotatedRefreshToken = 'rotated-refresh-token';

  late Dio dio;
  late _StubHttpClientAdapter adapter;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': expiredAccessToken,
      'refresh_token': refreshToken,
    });

    adapter = _StubHttpClientAdapter();
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.test/',
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(dio));
  });

  tearDown(() {
    dio.close(force: true);
  });

  test(
    'should_refresh_once_and_retry_original_request_when_access_token_is_expired',
    () async {
      adapter.handler = (options) async {
        if (options.path == ApiEndpoints.refreshToken) {
          expect(options.headers.containsKey('Authorization'), isFalse);
          expect(options.data, {'refresh_token': refreshToken});
          return _jsonResponse(
            200,
            body: {
              'status': 'success',
              'data': {
                'token': refreshedAccessToken,
                'refresh_token': rotatedRefreshToken,
              },
            },
          );
        }

        if (options.headers['Authorization'] ==
            'Bearer $refreshedAccessToken') {
          return _jsonResponse(200, body: {'status': 'success'});
        }

        return _jsonResponse(401, body: {'detail': 'Token is expired'});
      };

      final response = await dio.get<Map<String, dynamic>>('/protected/');

      expect(response.statusCode, 200);
      expect(adapter.requestCount(ApiEndpoints.refreshToken), 1);
      expect(adapter.requestCount('/protected/'), 2);
      expect(await SecureStorageService.getAccessToken(), refreshedAccessToken);
      expect(await SecureStorageService.getRefreshToken(), rotatedRefreshToken);
    },
  );

  test(
    'should_not_refresh_again_when_retried_request_is_still_unauthorized',
    () async {
      adapter.handler = (options) async {
        if (options.path == ApiEndpoints.refreshToken) {
          return _jsonResponse(
            200,
            body: {
              'status': 'success',
              'data': {
                'token': refreshedAccessToken,
                'refresh_token': rotatedRefreshToken,
              },
            },
          );
        }
        return _jsonResponse(401, body: {'detail': 'Unauthorized'});
      };

      await expectLater(
        dio.get<void>('/protected/'),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'status code',
            401,
          ),
        ),
      );

      expect(adapter.requestCount(ApiEndpoints.refreshToken), 1);
      expect(adapter.requestCount('/protected/'), 2);
    },
  );

  test(
    'should_clear_tokens_without_recursion_when_refresh_token_is_rejected',
    () async {
      adapter.handler = (options) async {
        if (options.path == ApiEndpoints.refreshToken) {
          return _jsonResponse(401, body: {'code': 'token_not_valid'});
        }
        return _jsonResponse(401, body: {'detail': 'Token is expired'});
      };

      await expectLater(
        dio.get<void>('/protected/'),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'status code',
            401,
          ),
        ),
      );

      expect(adapter.requestCount(ApiEndpoints.refreshToken), 1);
      expect(adapter.requestCount('/protected/'), 1);
      expect(await SecureStorageService.getAccessToken(), isNull);
      expect(await SecureStorageService.getRefreshToken(), isNull);
    },
  );

  test(
    'should_share_one_refresh_request_when_multiple_requests_receive_401',
    () async {
      final refreshStarted = Completer<void>();
      final allowRefreshToFinish = Completer<void>();

      adapter.handler = (options) async {
        if (options.path == ApiEndpoints.refreshToken) {
          if (!refreshStarted.isCompleted) {
            refreshStarted.complete();
          }
          await allowRefreshToFinish.future;
          return _jsonResponse(
            200,
            body: {
              'status': 'success',
              'data': {
                'token': refreshedAccessToken,
                'refresh_token': rotatedRefreshToken,
              },
            },
          );
        }

        if (options.headers['Authorization'] ==
            'Bearer $refreshedAccessToken') {
          return _jsonResponse(200, body: {'status': 'success'});
        }

        return _jsonResponse(401, body: {'detail': 'Token is expired'});
      };

      final responses = Future.wait([
        dio.get<void>('/protected/one/'),
        dio.get<void>('/protected/two/'),
      ]);

      await refreshStarted.future;
      allowRefreshToFinish.complete();
      final result = await responses;

      expect(result.map((response) => response.statusCode), everyElement(200));
      expect(adapter.requestCount(ApiEndpoints.refreshToken), 1);
    },
  );

  test(
    'should_reuse_rotated_token_when_a_delayed_401_arrives_after_refresh',
    () async {
      final allowDelayedUnauthorized = Completer<void>();
      var delayedRequestCount = 0;

      adapter.handler = (options) async {
        if (options.path == ApiEndpoints.refreshToken) {
          return _jsonResponse(
            200,
            body: {
              'status': 'success',
              'data': {
                'token': refreshedAccessToken,
                'refresh_token': rotatedRefreshToken,
              },
            },
          );
        }

        if (options.headers['Authorization'] ==
            'Bearer $refreshedAccessToken') {
          return _jsonResponse(200, body: {'status': 'success'});
        }

        if (options.path == '/protected/delayed/' &&
            delayedRequestCount++ == 0) {
          await allowDelayedUnauthorized.future;
        }
        return _jsonResponse(401, body: {'detail': 'Token is expired'});
      };

      final delayedResponse = dio.get<void>('/protected/delayed/');
      final immediateResponse = await dio.get<void>('/protected/immediate/');
      allowDelayedUnauthorized.complete();

      expect(immediateResponse.statusCode, 200);
      expect((await delayedResponse).statusCode, 200);
      expect(adapter.requestCount(ApiEndpoints.refreshToken), 1);
    },
  );

  test(
    'should_preserve_tokens_when_refresh_fails_due_to_network_error',
    () async {
      adapter.handler = (options) async {
        if (options.path == ApiEndpoints.refreshToken) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'No network',
          );
        }
        return _jsonResponse(401, body: {'detail': 'Token is expired'});
      };

      await expectLater(
        dio.get<void>('/protected/'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requestCount(ApiEndpoints.refreshToken), 1);
      expect(await SecureStorageService.getAccessToken(), expiredAccessToken);
      expect(await SecureStorageService.getRefreshToken(), refreshToken);
    },
  );

  test(
    'should_emit_session_expired_exactly_once_when_refresh_token_is_rejected',
    () async {
      final expiredEvents = <void>[];
      final subscription = AuthSessionEvents.sessionExpired.listen(
        expiredEvents.add,
      );
      addTearDown(subscription.cancel);

      adapter.handler = (options) async {
        if (options.path == ApiEndpoints.refreshToken) {
          return _jsonResponse(401, body: {'code': 'token_not_valid'});
        }
        return _jsonResponse(401, body: {'detail': 'Token is expired'});
      };

      await expectLater(
        dio.get<void>('/protected/'),
        throwsA(isA<DioException>()),
      );
      await pumpEventQueue();

      expect(expiredEvents, hasLength(1));
      expect(await SecureStorageService.getAccessToken(), isNull);
      expect(await SecureStorageService.getRefreshToken(), isNull);
    },
  );

  test(
    'should_not_emit_session_expired_when_refresh_fails_due_to_network_error',
    () async {
      final expiredEvents = <void>[];
      final subscription = AuthSessionEvents.sessionExpired.listen(
        expiredEvents.add,
      );
      addTearDown(subscription.cancel);

      adapter.handler = (options) async {
        if (options.path == ApiEndpoints.refreshToken) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'No network',
          );
        }
        return _jsonResponse(401, body: {'detail': 'Token is expired'});
      };

      await expectLater(
        dio.get<void>('/protected/'),
        throwsA(isA<DioException>()),
      );
      await pumpEventQueue();

      expect(expiredEvents, isEmpty);
      expect(await SecureStorageService.getAccessToken(), expiredAccessToken);
      expect(await SecureStorageService.getRefreshToken(), refreshToken);
    },
  );

  test('should_redact_authentication_secrets_from_network_logs', () async {
    const accessSecret = 'secret-access-value';
    const refreshSecret = 'secret-refresh-value';
    const rotatedSecret = 'secret-rotated-value';
    final capturedLogs = <String>[];
    final loggingDio = Dio(BaseOptions(baseUrl: 'https://api.example.test/'));
    final loggingAdapter = _StubHttpClientAdapter()
      ..handler = (_) async => _jsonResponse(
        200,
        body: {
          'status': 'success',
          'data': {'token': accessSecret, 'refresh_token': rotatedSecret},
        },
      );
    loggingDio.httpClientAdapter = loggingAdapter;
    loggingDio.interceptors.add(LoggingInterceptor());

    await runZoned(
      () => loggingDio.post<void>(
        ApiEndpoints.refreshToken,
        data: const {'refresh_token': refreshSecret},
        options: Options(
          headers: const {'Authorization': 'Bearer $accessSecret'},
        ),
      ),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => capturedLogs.add(line),
      ),
    );
    loggingDio.close(force: true);

    final output = capturedLogs.join('\n');
    expect(output, contains('[REDACTED]'));
    expect(output, isNot(contains(accessSecret)));
    expect(output, isNot(contains(refreshSecret)));
    expect(output, isNot(contains(rotatedSecret)));
  });
}

ResponseBody _jsonResponse(int statusCode, {required Object body}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _StubHttpClientAdapter implements HttpClientAdapter {
  late Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  int requestCount(String path) {
    return requests.where((request) => request.path == path).length;
  }

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
