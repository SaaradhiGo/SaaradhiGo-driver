import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/features/documents/data/data_sources/documents_remote_data_source.dart';

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
  late DocumentsRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://dev.api.saaradhigo.com/'));
    adapter = _StubHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    dataSource = DocumentsRemoteDataSourceImpl(dio);
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

  test(
    'getProfileForDocuments fetches driver profile with documents',
    () async {
      adapter.handler = (options) async {
        expect(options.path, equals(ApiEndpoints.driverProfile));
        return jsonResponse({
          'status': 'success',
          'data': {
            'id': 1,
            'license_doc': 'https://s3.amazonaws.com/bucket/licence.jpg',
            'license_expiry': '2028-10-10',
            'active_vehicle_details': {
              'rc_doc': 'https://s3.amazonaws.com/bucket/rc.pdf',
            },
          },
        });
      };

      final profile = await dataSource.getProfileForDocuments();
      expect(profile.licenseDoc, contains('licence.jpg'));
      expect(profile.licenseExpiry?.year, equals(2028));
      expect(profile.activeVehicleDetails?['rc_doc'], contains('rc.pdf'));
    },
  );

  test('updateDriverDocument calls PATCH driverUpdate', () async {
    adapter.handler = (options) async {
      expect(options.method, equals('PATCH'));
      expect(options.path, equals(ApiEndpoints.driverUpdate));
      expect(options.data, equals({'license_doc': 's3_key_123'}));
      return jsonResponse({'status': 'success', 'data': {}});
    };

    await dataSource.updateDriverDocument({'license_doc': 's3_key_123'});
    expect(adapter.requests.length, equals(1));
  });

  test('updateVehicleDocument calls PATCH on vehicle endpoint', () async {
    adapter.handler = (options) async {
      expect(options.method, equals('PATCH'));
      expect(options.path, equals(ApiEndpoints.updateVehicle('5')));
      expect(options.data, equals({'rc_doc': 's3_rc_key'}));
      return jsonResponse({'status': 'success', 'data': {}});
    };

    await dataSource.updateVehicleDocument(5, {'rc_doc': 's3_rc_key'});
    expect(adapter.requests.length, equals(1));
  });
}
