import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/notification_model.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_providers.dart';

class NotificationsNotifier extends Notifier<NotificationsState> {
  late NotificationsRepository _repository;

  @override
  NotificationsState build() {
    try {
      _repository = ref.watch(notificationsRepositoryProvider);
    } catch (_) {
      // Test environment fallback
    }
    return const NotificationsState();
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    if (refresh) {
      state = state.copyWith(status: NotificationsStatus.refreshing);
    } else {
      state = state.copyWith(status: NotificationsStatus.loading);
    }

    try {
      final items = await _repository.getNotifications(
        page: 1,
        pageSize: 20,
        category: state.selectedCategory,
      );

      final unread = items.where((n) => !n.isRead).length;

      if (items.isEmpty) {
        state = state.copyWith(
          status: NotificationsStatus.empty,
          notifications: [],
          unreadCount: unread,
          page: 1,
          hasMore: false,
        );
      } else {
        state = state.copyWith(
          status: NotificationsStatus.success,
          notifications: items,
          unreadCount: unread,
          page: 1,
          hasMore: items.length >= 20,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.isLoading ||
        state.isRefreshing) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    try {
      final newItems = await _repository.getNotifications(
        page: nextPage,
        pageSize: 20,
        category: state.selectedCategory,
      );

      final combined = [...state.notifications, ...newItems];
      final unread = combined.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: combined,
        unreadCount: unread,
        page: nextPage,
        hasMore: newItems.length >= 20,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setCategory(NotificationCategory category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
    fetchNotifications();
  }

  Future<void> markAsRead(int notificationId) async {
    // Optimistic update
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    final unread = updated.where((n) => !n.isRead).length;
    state = state.copyWith(notifications: updated, unreadCount: unread);

    try {
      await _repository.markNotificationAsRead(notificationId);
    } catch (_) {
      // Best-effort background sync
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);

    try {
      await _repository.markAllNotificationsAsRead();
    } catch (_) {
      // Best-effort
    }
  }
}
