import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../domain/models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = 20,
    NotificationCategory? category,
  });

  Future<void> markNotificationAsRead(int notificationId);

  Future<void> markAllNotificationsAsRead();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final Dio dio;

  NotificationsRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'] as List<dynamic>? ?? [];
      }
      if (data is List) {
        return data;
      }
      if (responseData.containsKey('results')) {
        return responseData['results'] as List<dynamic>? ?? [];
      }
    }
    if (responseData is List) {
      return responseData;
    }
    return [];
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = 20,
    NotificationCategory? category,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'page_size': pageSize};

    final response = await dio.get(
      ApiEndpoints.notifications,
      queryParameters: queryParams,
    );

    final rawList = _extractList(response.data);
    final notifications = rawList
        .map(
          (e) =>
              NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    if (category != null && category != NotificationCategory.all) {
      return notifications.where((n) => n.category == category).toList();
    }

    return notifications;
  }

  @override
  Future<void> markNotificationAsRead(int notificationId) async {
    await dio.patch(ApiEndpoints.notificationRead(notificationId));
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    await dio.post(ApiEndpoints.notificationsReadAll);
  }
}
