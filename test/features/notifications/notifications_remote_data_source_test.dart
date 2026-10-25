import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/domain/models/notification_model.dart';
import 'package:saaradhigo_driver/features/notifications/data/data_sources/notifications_remote_data_source.dart';

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
  late NotificationsRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://dev.api.saaradhigo.com/'));
    adapter = _StubHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    dataSource = NotificationsRemoteDataSourceImpl(dio);
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
    'getNotifications fetches notifications with pagination query parameters',
    () async {
      adapter.handler = (options) async {
        expect(options.path, equals(ApiEndpoints.notifications));
        expect(options.queryParameters['page'], equals(1));
        expect(options.queryParameters['page_size'], equals(20));

        return jsonResponse({
          'status': 'success',
          'data': {
            'count': 2,
            'results': [
              {
                'id': 101,
                'title': 'Earnings Added',
                'message': '₹350 credited to your account',
                'is_read': false,
                'type': 'earnings',
                'created_at': '2026-09-04T10:00:00Z',
              },
              {
                'id': 102,
                'title': 'KYC Verified',
                'message': 'Documents verified',
                'is_read': true,
                'type': 'system',
                'created_at': '2026-09-04T09:00:00Z',
              },
            ],
          },
        });
      };

      final notifications = await dataSource.getNotifications(
        page: 1,
        pageSize: 20,
      );
      expect(notifications.length, equals(2));
      expect(notifications[0].id, equals(101));
      expect(notifications[0].category, equals(NotificationCategory.earnings));
      expect(notifications[1].category, equals(NotificationCategory.system));
    },
  );

  test('markNotificationAsRead calls PATCH on correct endpoint', () async {
    adapter.handler = (options) async {
      expect(options.method, equals('PATCH'));
      expect(options.path, equals(ApiEndpoints.notificationRead(101)));
      return jsonResponse({
        'status': 'success',
        'data': {'message': 'Marked as read'},
      });
    };

    await dataSource.markNotificationAsRead(101);
    expect(adapter.requests.length, equals(1));
  });

  test('markAllNotificationsAsRead calls POST on correct endpoint', () async {
    adapter.handler = (options) async {
      expect(options.method, equals('POST'));
      expect(options.path, equals(ApiEndpoints.notificationsReadAll));
      return jsonResponse({
        'status': 'success',
        'data': {'message': 'All marked as read'},
      });
    };

    await dataSource.markAllNotificationsAsRead();
    expect(adapter.requests.length, equals(1));
  });
}
