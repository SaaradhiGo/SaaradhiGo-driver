import '../../../../domain/models/notification_model.dart';

enum NotificationsStatus { initial, loading, success, empty, error, refreshing }

class NotificationsState {
  final NotificationsStatus status;
  final List<NotificationModel> notifications;
  final NotificationCategory selectedCategory;
  final int unreadCount;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.selectedCategory = NotificationCategory.all,
    this.unreadCount = 0,
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get isLoading => status == NotificationsStatus.loading;
  bool get isRefreshing => status == NotificationsStatus.refreshing;
  bool get isEmpty => status == NotificationsStatus.empty;
  bool get hasError => status == NotificationsStatus.error;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationModel>? notifications,
    NotificationCategory? selectedCategory,
    int? unreadCount,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
