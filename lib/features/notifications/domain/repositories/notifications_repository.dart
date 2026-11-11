import '../../../../domain/models/notification_model.dart';

abstract class NotificationsRepository {
  /// Fetches a paginated list of notifications, optionally filtered by category.
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = 20,
    NotificationCategory? category,
  });

  /// Marks a specific notification as read.
  Future<void> markNotificationAsRead(int notificationId);

  /// Marks all notifications as read.
  Future<void> markAllNotificationsAsRead();
}
