import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/notification_model.dart';
import 'package:saaradhigo_driver/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:saaradhigo_driver/features/notifications/presentation/providers/notifications_providers.dart';

class StubNotificationsRepository implements NotificationsRepository {
  bool shouldThrow = false;
  List<NotificationModel> notificationsToReturn = [
    NotificationModel(
      id: 1,
      title: 'Earnings Credited',
      message: '₹500 added to your wallet',
      isRead: false,
      type: 'earnings',
      createdAt: DateTime.now(),
    ),
    NotificationModel(
      id: 2,
      title: 'New Trip Scheduled',
      message: 'Pickup in Ameerpet',
      isRead: true,
      type: 'trip',
      createdAt: DateTime.now(),
    ),
  ];

  int? markedReadId;
  bool markAllCalled = false;

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = 20,
    NotificationCategory? category,
  }) async {
    if (shouldThrow) throw Exception('API Error');
    if (category != null && category != NotificationCategory.all) {
      return notificationsToReturn
          .where((n) => n.category == category)
          .toList();
    }
    return notificationsToReturn;
  }

  @override
  Future<void> markNotificationAsRead(int notificationId) async {
    if (shouldThrow) throw Exception('API Error');
    markedReadId = notificationId;
    notificationsToReturn = notificationsToReturn.map((n) {
      if (n.id == notificationId) return n.copyWith(isRead: true);
      return n;
    }).toList();
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    if (shouldThrow) throw Exception('API Error');
    markAllCalled = true;
    notificationsToReturn = notificationsToReturn
        .map((n) => n.copyWith(isRead: true))
        .toList();
  }
}

void main() {
  late StubNotificationsRepository stubRepo;
  late ProviderContainer container;

  setUp(() {
    stubRepo = StubNotificationsRepository();
    container = ProviderContainer(
      overrides: [notificationsRepositoryProvider.overrideWithValue(stubRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'initial build triggers fetch and populates notifications and unread count',
    () async {
      final notifier = container.read(notificationsNotifierProvider.notifier);
      await notifier.fetchNotifications();

      final state = container.read(notificationsNotifierProvider);
      expect(state.status, NotificationsStatus.success);
      expect(state.notifications.length, 2);
      expect(state.unreadCount, 1);

      final unreadProviderCount = container.read(
        unreadNotificationsCountProvider,
      );
      expect(unreadProviderCount, 1);
    },
  );

  test('setCategory filters notifications correctly', () async {
    final notifier = container.read(notificationsNotifierProvider.notifier);
    await notifier.fetchNotifications();

    notifier.setCategory(NotificationCategory.earnings);
    await Future.delayed(Duration.zero);

    final state = container.read(notificationsNotifierProvider);
    expect(state.selectedCategory, NotificationCategory.earnings);
    expect(
      state.notifications.every(
        (n) => n.category == NotificationCategory.earnings,
      ),
      isTrue,
    );
  });

  test(
    'markAsRead updates item optimistically and decrements unread count',
    () async {
      final notifier = container.read(notificationsNotifierProvider.notifier);
      await notifier.fetchNotifications();

      await notifier.markAsRead(1);

      final state = container.read(notificationsNotifierProvider);
      final item = state.notifications.firstWhere((n) => n.id == 1);
      expect(item.isRead, isTrue);
      expect(state.unreadCount, 0);
      expect(stubRepo.markedReadId, 1);
    },
  );

  test(
    'markAllAsRead marks all notifications as read and resets unread count to zero',
    () async {
      final notifier = container.read(notificationsNotifierProvider.notifier);
      await notifier.fetchNotifications();

      await notifier.markAllAsRead();

      final state = container.read(notificationsNotifierProvider);
      expect(state.notifications.every((n) => n.isRead), isTrue);
      expect(state.unreadCount, 0);
      expect(stubRepo.markAllCalled, isTrue);
    },
  );

  test('fetch failure sets error status and error message', () async {
    stubRepo.shouldThrow = true;
    final notifier = container.read(notificationsNotifierProvider.notifier);
    await notifier.fetchNotifications();

    final state = container.read(notificationsNotifierProvider);
    expect(state.status, NotificationsStatus.error);
    expect(state.errorMessage, isNotNull);
  });
}
