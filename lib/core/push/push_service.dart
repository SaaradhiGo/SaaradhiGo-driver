import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles a data message that arrives while the app is terminated.
///
/// Must be a top-level function — Flutter spawns a separate isolate for it,
/// so nothing from the app's object graph is available here.
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Intentionally minimal. The socket is the source of truth for dispatch;
  // this exists so the OS wakes the app and the notification is shown. Doing
  // real work here would race the foreground isolate.
  debugPrint('PushService: background message ${message.messageId}');
}

/// Firebase Cloud Messaging.
///
/// Push is the *fallback* dispatch channel. The backend sends a data push
/// alongside every WebSocket offer, so a driver whose socket dropped (screen
/// off, doze, dead Wi-Fi) still gets buzzed. Because it is redundant, every
/// failure path here degrades quietly rather than blocking startup.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _token;

  /// The FCM token, sent to the server at login so dispatch can reach this
  /// device. Null when push is unavailable.
  String? get token => _token;

  /// High-importance channel so a ride offer makes a sound and shows a
  /// heads-up banner even in Do Not Disturb's "priority only" mode. A silent
  /// ride offer is a missed ride.
  static const AndroidNotificationChannel _rideChannel =
      AndroidNotificationChannel(
    'ride_requests',
    'Ride requests',
    description: 'New ride offers and trip updates',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();

      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_rideChannel);

      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _token = await messaging.getToken();
      FirebaseMessaging.onMessage.listen(_showForeground);

      _ready = true;
    } on Object catch (e) {
      // No Firebase config, no Play Services, no network at launch — all
      // survivable. Log and carry on.
      debugPrint('PushService: disabled ($e)');
      _ready = false;
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if (title == null && body == null) return;

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _rideChannel.id,
          _rideChannel.name,
          channelDescription: _rideChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Re-read the token — call after login so a token that rotated while the
  /// driver was signed out still reaches the server.
  Future<String?> refreshToken() async {
    if (!_ready) return null;
    try {
      _token = await FirebaseMessaging.instance.getToken();
      return _token;
    } on Object catch (e) {
      debugPrint('PushService.refreshToken: $e');
      return null;
    }
  }
}
