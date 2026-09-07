import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/notifications_remote_data_source.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_notifier.dart';
import 'notifications_state.dart';

export 'notifications_notifier.dart';
export 'notifications_state.dart';

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
      return NotificationsRemoteDataSourceImpl(
        ref.watch(dioClientProvider).dio,
      );
    });

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteDataSourceProvider),
  );
});

final notificationsNotifierProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(() {
      return NotificationsNotifier();
    });

final unreadNotificationsCountProvider = Provider<int>((ref) {
  try {
    final state = ref.watch(notificationsNotifierProvider);
    return state.unreadCount;
  } catch (_) {
    return 0;
  }
});
