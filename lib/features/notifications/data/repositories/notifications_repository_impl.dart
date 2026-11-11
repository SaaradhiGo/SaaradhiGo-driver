import '../../../../domain/models/notification_model.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../data_sources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;

  NotificationsRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = 20,
    NotificationCategory? category,
  }) async {
    return await remoteDataSource.getNotifications(
      page: page,
      pageSize: pageSize,
      category: category,
    );
  }

  @override
  Future<void> markNotificationAsRead(int notificationId) async {
    await remoteDataSource.markNotificationAsRead(notificationId);
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    await remoteDataSource.markAllNotificationsAsRead();
  }
}
