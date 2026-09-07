import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/features/vehicle/data/data_sources/vehicles_remote_data_source.dart';

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
  late VehiclesRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://dev.api.saaradhigo.in/'));
    adapter = _StubHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    dataSource = VehiclesRemoteDataSourceImpl(dio);
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

  test('getVehicles fetches fleet vehicles list', () async {
    adapter.handler = (options) async {
      expect(options.path, equals(ApiEndpoints.driverVehicles));
      return jsonResponse({
        'status': 'success',
        'data': {
          'count': 1,
          'results': [
            {
              'id': 1,
              'vehicle_number': 'TS07AB1234',
              'vehicle_type': {'id': 2, 'type': 'sedan'},
              'brand': 'Maruti',
              'model': 'Swift Dzire',
              'status': 'active',
            },
          ],
        },
      });
    };

    final vehicles = await dataSource.getVehicles();
    expect(vehicles.length, equals(1));
    expect(vehicles.first.vehicleNumber, equals('TS07AB1234'));
    expect(vehicles.first.model, equals('Swift Dzire'));
  });

  test(
    'switchActiveVehicle calls driverUpdate with active_vehicle id',
    () async {
      adapter.handler = (options) async {
        expect(options.method, equals('PATCH'));
        expect(options.path, equals(ApiEndpoints.driverUpdate));
        expect(options.data, equals({'active_vehicle': 10}));
        return jsonResponse({'status': 'success', 'data': {}});
      };

      await dataSource.switchActiveVehicle(10);
      expect(adapter.requests.length, equals(1));
    },
  );

  test('updateVehicle calls PATCH on vehicle endpoint', () async {
    adapter.handler = (options) async {
      expect(options.method, equals('PATCH'));
      expect(options.path, equals(ApiEndpoints.updateVehicle('10')));
      expect(options.data, equals({'color': 'Black'}));
      return jsonResponse({
        'status': 'success',
        'data': {
          'id': 10,
          'vehicle_number': 'TS07AB1234',
          'vehicle_type': 'sedan',
          'color': 'Black',
        },
      });
    };

    final updated = await dataSource.updateVehicle(10, {'color': 'Black'});
    expect(updated.color, equals('Black'));
  });

  test(
    'addVehicleWithKeys posts vehicle payload to addVehicle endpoint',
    () async {
      adapter.handler = (options) async {
        expect(options.method, equals('POST'));
        expect(options.path, equals(ApiEndpoints.addVehicle));
        expect(options.data['vehicle_number'], equals('TS09XY9999'));
        expect(options.data['vehicle_type'], equals('sedan'));
        expect(options.data['rc_doc'], equals('uploads/rc.pdf'));
        return jsonResponse({
          'status': 'success',
          'data': {
            'id': 42,
            'vehicle_number': 'TS09XY9999',
            'vehicle_type': 'sedan',
            'make': 'Hyundai',
            'model': 'Verna',
            'rc_doc': 'uploads/rc.pdf',
          },
        });
      };

      final result = await dataSource.addVehicleWithKeys({
        'vehicle_number': 'TS09XY9999',
        'vehicle_type': 'sedan',
        'make': 'Hyundai',
        'model': 'Verna',
        'rc_doc': 'uploads/rc.pdf',
      });

      expect(result['id'], equals(42));
      expect(result['vehicle_number'], equals('TS09XY9999'));
    },
  );
}
