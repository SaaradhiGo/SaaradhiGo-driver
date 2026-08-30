import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/core/network/logging_interceptor.dart';
import 'package:saaradhigo_driver/core/uploads/presigned_upload_service.dart';
import 'package:saaradhigo_driver/core/uploads/upload_exceptions.dart';
import 'package:saaradhigo_driver/core/uploads/upload_kind.dart';

/// Hand-rolled adapter stub capturing every request (same pattern as
/// test/core/network/auth_interceptor_test.dart).
class _StubHttpClientAdapter implements HttpClientAdapter {
  late Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];
  final List<Uint8List?> bodies = [];

  int requestCount(String path) =>
      requests.where((request) => request.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      bodies.add(chunks.isEmpty ? null : chunks.first);
    } else {
      bodies.add(null);
    }
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
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

ResponseBody _emptyResponse(int statusCode) {
  return ResponseBody.fromString('', statusCode);
}

const _signedUrl =
    'https://bucket.s3.amazonaws.com/rc_docs/abcdef0123456789abcdef0123456789.png'
    '?X-Amz-Signature=deadbeef&X-Amz-Expires=900';

Map<String, dynamic> _presignBody({String contentType = 'image/png'}) => {
  'status': 'success',
  'data': {
    'kind': 'rc_doc',
    'key': 'rc_docs/abcdef0123456789abcdef0123456789.png',
    'upload_url': _signedUrl,
    'expires_in': 900,
    'method': 'PUT',
    'headers': {'Content-Type': contentType},
  },
};

Uint8List pngBytes() => Uint8List.fromList([1, 2, 3, 4, 5]);

dynamic _decodedBody(RequestOptions request) {
  final data = request.data;
  return data is String ? jsonDecode(data) : data;
}

void main() {
  late Dio dio;
  late _StubHttpClientAdapter adapter;
  late PresignedUploadService service;
  late DateTime currentTime;

  late Dio s3Dio;

  setUp(() {
    currentTime = DateTime(2026, 8, 26, 12, 0, 0);
    adapter = _StubHttpClientAdapter()
      ..handler = (_) async => _jsonResponse(200, body: _presignBody());
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1/'));
    dio.httpClientAdapter = adapter;
    // The S3 client shares the stubbed adapter so PUTs never hit real HTTP.
    s3Dio = Dio();
    s3Dio.httpClientAdapter = adapter;
    service = PresignedUploadService(
      dio: dio,
      now: () => currentTime,
      s3Client: s3Dio,
    );
  });

  RequestOptions? lastPut(_StubHttpClientAdapter a) {
    for (final request in a.requests.reversed) {
      if (request.method == 'PUT') {
        return request;
      }
    }
    return null;
  }

  group('presign request', () {
    test('posts kind and content_type to /uploads/presign/', () async {
      await service.upload(
        kind: UploadKind.rcDoc,
        bytes: pngBytes(),
        mimeType: 'image/png',
      );

      expect(adapter.requestCount(ApiEndpoints.presignUpload), 1);
      final request = adapter.requests.first;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/v1/uploads/presign/');
      expect(_decodedBody(request), {
        'kind': 'rc_doc',
        'content_type': 'image/png',
      });
    });
  });

  group('S3 PUT', () {
    test(
      'uses the exact presigned URL, Content-Type and raw-byte body',
      () async {
        final result = await service.upload(
          kind: UploadKind.rcDoc,
          bytes: pngBytes(),
          mimeType: 'image/png',
        );

        // Step 1: presign. Step 2: direct PUT. No third request.
        expect(adapter.requests, hasLength(2));

        final put = lastPut(adapter)!;
        expect(put.uri.toString(), _signedUrl);
        expect(put.method, 'PUT');

        // Content-Type must be byte-for-byte the presigned value (no charset).
        final contentTypeHeader = put.headers.entries
            .firstWhere((e) => e.key.toLowerCase() == 'content-type')
            .value;
        expect(contentTypeHeader, 'image/png');
        expect(put.contentType, 'image/png');

        // Never attach Authorization/JWT or x-amz-* headers to the S3 request.
        expect(put.headers.containsKey('authorization'), isFalse);
        expect(
          put.headers.keys.any((key) => key.toLowerCase().startsWith('x-amz-')),
          isFalse,
        );

        // Raw bytes, never multipart/form-data.
        expect(adapter.bodies.last, pngBytes());

        expect(result.key, 'rc_docs/abcdef0123456789abcdef0123456789.png');
      },
    );

    test('re-presigns exactly once and retries when S3 answers 403', () async {
      var putCalls = 0;
      adapter.handler = (options) async {
        if (options.method == 'PUT') {
          putCalls++;
          return putCalls == 1 ? _emptyResponse(403) : _emptyResponse(200);
        }
        return _jsonResponse(200, body: _presignBody());
      };

      final result = await service.upload(
        kind: UploadKind.rcDoc,
        bytes: pngBytes(),
        mimeType: 'image/png',
      );

      expect(result.key, 'rc_docs/abcdef0123456789abcdef0123456789.png');
      expect(adapter.requestCount(ApiEndpoints.presignUpload), 2);
      expect(putCalls, 2);
    });

    test(
      'surfaces the error after the single 403 retry is exhausted',
      () async {
        adapter.handler = (options) async {
          if (options.method == 'PUT') {
            return _emptyResponse(403);
          }
          return _jsonResponse(200, body: _presignBody());
        };

        await expectLater(
          service.upload(
            kind: UploadKind.rcDoc,
            bytes: pngBytes(),
            mimeType: 'image/png',
          ),
          throwsA(isA<UploadForbiddenException>()),
        );

        // Exactly one re-presign: two presigns, two PUTs, then give up.
        expect(adapter.requestCount(ApiEndpoints.presignUpload), 2);
        expect(adapter.requests.where((r) => r.method == 'PUT'), hasLength(2));
      },
    );

    test(
      'maps connection errors during PUT to UploadNetworkException',
      () async {
        adapter.handler = (options) async {
          if (options.method == 'PUT') {
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'airplane mode',
            );
          }
          return _jsonResponse(200, body: _presignBody());
        };

        await expectLater(
          service.upload(
            kind: UploadKind.rcDoc,
            bytes: pngBytes(),
            mimeType: 'image/png',
          ),
          throwsA(isA<UploadNetworkException>()),
        );
      },
    );
  });

  group('presign failure handling', () {
    test('400 INVALID_CONTENT_TYPE maps to validation error', () async {
      adapter.handler = (_) async => _jsonResponse(
        400,
        body: {
          'status': 'error',
          'error': {
            'code': 'INVALID_CONTENT_TYPE',
            'message': 'content_type not allowed for kind rc_doc',
          },
        },
      );

      await expectLater(
        service.upload(
          kind: UploadKind.rcDoc,
          bytes: pngBytes(),
          // Passes client-side validation; the server still rejects it.
          mimeType: 'image/png',
        ),
        throwsA(
          isA<UploadValidationException>().having(
            (e) => e.message,
            'message',
            'content_type not allowed for kind rc_doc',
          ),
        ),
      );
    });

    test('403 DRIVER_REQUIRED maps to forbidden with server message', () async {
      adapter.handler = (_) async => _jsonResponse(
        403,
        body: {
          'status': 'error',
          'error': {
            'code': 'DRIVER_REQUIRED',
            'message': 'Driver account required.',
          },
        },
      );

      await expectLater(
        service.upload(
          kind: UploadKind.licenseDoc,
          bytes: pngBytes(),
          mimeType: 'image/png',
        ),
        throwsA(
          isA<UploadForbiddenException>().having(
            (e) => e.message,
            'message',
            'Driver account required.',
          ),
        ),
      );
    });
  });

  group('expiry risk window', () {
    test('effective window honours expires_in and the 10 minute cap', () {
      // expires_in 900s > cap: capped at 10 minutes.
      expect(
        PresignedUploadService.effectiveRiskWindow(900),
        const Duration(minutes: 10),
      );
      // Short grants shrink below the cap, minus the drift margin.
      expect(
        PresignedUploadService.effectiveRiskWindow(300),
        const Duration(seconds: 270),
      );
    });

    test(
      'aborts without a PUT when the risk window elapsed since presign',
      () async {
        // now() is called first for the presign timestamp, then again for the
        // risk-window check before the PUT. Return a post-window time from the
        // second call onward to simulate a stalled upload deterministically.
        final base = DateTime(2026, 8, 26, 12, 0, 0);
        var clockCalls = 0;
        var expiredSeen = false;
        final clockS3Dio = Dio()..httpClientAdapter = adapter;
        final clockService = PresignedUploadService(
          dio: dio,
          now: () {
            clockCalls++;
            return clockCalls == 1
                ? base
                : base.add(const Duration(minutes: 11));
          },
          s3Client: clockS3Dio,
        );

        await expectLater(
          clockService
              .upload(
                kind: UploadKind.rcDoc,
                bytes: pngBytes(),
                mimeType: 'image/png',
              )
              .catchError((Object e) {
                expiredSeen = e is UploadExpiredException;
                throw e;
              }),
          throwsA(isA<UploadExpiredException>()),
        );

        expect(expiredSeen, isTrue);
        expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
      },
    );
  });

  group('client-side validation', () {
    test('rejects oversized images before any network call', () async {
      final tooBig = Uint8List(5 * 1024 * 1024 + 1);

      await expectLater(
        service.upload(
          kind: UploadKind.avatar,
          bytes: tooBig,
          mimeType: 'image/png',
        ),
        throwsA(
          isA<UploadValidationException>().having(
            (e) => e.message,
            'message',
            contains('5 MB'),
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
    });

    test('rejects disallowed MIME types before any network call', () async {
      await expectLater(
        service.upload(
          kind: UploadKind.rcDoc,
          bytes: pngBytes(),
          mimeType: 'application/zip',
        ),
        throwsA(isA<UploadValidationException>()),
      );

      // PDFs are valid for documents but never for avatars.
      await expectLater(
        service.upload(
          kind: UploadKind.avatar,
          bytes: pngBytes(),
          mimeType: 'application/pdf',
        ),
        throwsA(isA<UploadValidationException>()),
      );
      expect(adapter.requests, isEmpty);
    });

    test('rejects empty payloads before any network call', () async {
      await expectLater(
        service.upload(
          kind: UploadKind.avatar,
          bytes: Uint8List(0),
          mimeType: 'image/png',
        ),
        throwsA(isA<UploadValidationException>()),
      );
      expect(adapter.requests, isEmpty);
    });
  });

  test('never logs the signed upload URL or authorization secrets', () async {
    const secretToken = 'secret-bearer-value';
    final capturedLogs = <String>[];

    final loggingDio = Dio(BaseOptions(baseUrl: 'https://api.example.test/'));
    loggingDio.httpClientAdapter = _StubHttpClientAdapter()
      ..handler = (_) async => _jsonResponse(200, body: _presignBody());
    loggingDio.interceptors.add(LoggingInterceptor());

    final loggingS3Dio = Dio()
      ..httpClientAdapter = loggingDio.httpClientAdapter;
    final loggingService = PresignedUploadService(
      dio: loggingDio,
      now: () => currentTime,
      s3Client: loggingS3Dio,
    );

    await runZoned(
      () => loggingDio
          .post<dynamic>(
            ApiEndpoints.presignUpload,
            data: const {'kind': 'rc_doc', 'content_type': 'image/png'},
            options: Options(headers: {'Authorization': 'Bearer $secretToken'}),
          )
          .then(
            (_) => loggingService.upload(
              kind: UploadKind.rcDoc,
              bytes: pngBytes(),
              mimeType: 'image/png',
            ),
          ),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => capturedLogs.add(line),
      ),
    );
    loggingDio.close(force: true);

    final output = capturedLogs.join('\n');
    expect(output, contains('[REDACTED]'));
    expect(output, isNot(contains(secretToken)));
    expect(output, isNot(contains(_signedUrl)));
    expect(output, isNot(contains('X-Amz-Signature')));
  });
}
