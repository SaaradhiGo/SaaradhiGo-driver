import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/models/notification_prefs.dart';

/// GET and PUT /notifications/preferences/ (servers/notifications/app_views.py).
/// The same endpoint serves riders and drivers.
class NotificationPreferencesService {
  NotificationPreferencesService(this.dio);
  final Dio dio;

  NotificationPrefs? _read(Response<dynamic> response) {
    final body = response.data;
    if (response.statusCode != 200 || body is! Map) return null;
    if (body['status'] != 'success') return null;
    return NotificationPrefs.fromData(body['data']);
  }

  /// The caller's effective choices, or null on any failure.
  Future<NotificationPrefs?> fetch() async {
    try {
      return _read(await dio.get(ApiEndpoints.notificationPreferences));
    } catch (_) {
      return null;
    }
  }

  /// Saves one explicit choice. Returns the server's view after the save, or
  /// null when it was not saved (the screen puts the switch back).
  Future<NotificationPrefs?> save({
    required String channel,
    required String category,
    required bool optedIn,
  }) async {
    try {
      return _read(
        await dio.put(
          ApiEndpoints.notificationPreferences,
          data: {
            'preferences': [
              {'channel': channel, 'category': category, 'opted_in': optedIn},
            ],
          },
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

final notificationPreferencesServiceProvider =
    Provider<NotificationPreferencesService>((ref) {
      return NotificationPreferencesService(ref.watch(dioClientProvider).dio);
    });
