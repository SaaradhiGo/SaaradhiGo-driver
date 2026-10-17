/// The Firebase-backed [PushTransport]. Deliberately thin.
///
/// Everything here is plugin glue that cannot run under `flutter test`. The
/// logic worth testing -- parsing, deduplication, stale rejection, token
/// registration, logout cleanup -- lives above the seam and is covered there.
/// Keep this file boring; if a decision starts to live in it, move the
/// decision up.
library;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/app_logger.dart';
import 'push_offer.dart';
import 'push_transport.dart';

/// Handles a data message while the app is backgrounded or terminated.
///
/// Must be a top-level function: Android runs it in a separate isolate with
/// no access to anything this isolate has set up. It cannot touch the UI or
/// the provider container, so it does nothing but initialise Firebase and
/// let the system display the notification. The tap is what brings the offer
/// into the app, through `onOpenedOffer` or `takeInitialOffer`.
@pragma('vm:entry-point')
Future<void> driverPushBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Nothing useful to do from a background isolate. The notification is
    // still shown by the system, because dispatch sends a notification block
    // alongside the data.
  }
}

/// The Android channel ride offers are posted to.
///
/// A ride offer has seconds of value, so it needs `Importance.max` to appear
/// as a heads-up notification over whatever is on screen. A channel's
/// importance is fixed when the channel is created -- changing these values
/// later has no effect on a phone that already has the channel, which is why
/// the id carries a version.
const AndroidNotificationChannel rideOfferChannel = AndroidNotificationChannel(
  'ride_offers_v1',
  'Ride offers',
  description: 'A rider is requesting a trip. These are time-critical.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

class FirebasePushTransport implements PushTransport {
  FirebasePushTransport({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _injectedMessaging = messaging,
       _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging? _injectedMessaging;
  final FlutterLocalNotificationsPlugin _local;

  FirebaseMessaging get _messaging =>
      _injectedMessaging ?? FirebaseMessaging.instance;

  final _foreground = StreamController<PushOffer>.broadcast();
  final _opened = StreamController<PushOffer>.broadcast();
  final _tokenRefresh = StreamController<String>.broadcast();

  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _initialOfferTaken = false;

  @override
  Stream<PushOffer> get onForegroundOffer => _foreground.stream;

  @override
  Stream<PushOffer> get onOpenedOffer => _opened.stream;

  @override
  Stream<String> get onTokenRefresh => _tokenRefresh.stream;

  @override
  Future<PushAvailability> initialize() async {
    try {
      await Firebase.initializeApp();
    } on Object catch (e) {
      // The expected state until android/app/google-services.json exists.
      // Not an error: the app dispatches over the WebSocket without push.
      AppLogger.w('FCM unavailable: Firebase could not start ($e)');
      return const PushAvailability.unavailable(
        PushUnavailableReason.notConfigured,
      );
    }

    try {
      FirebaseMessaging.onBackgroundMessage(driverPushBackgroundHandler);

      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(rideOfferChannel);

      // v22 takes named parameters.
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((message) {
          final offer = _parse(message, PushOfferSource.foreground);
          if (offer != null) _foreground.add(offer);
        }),
      );

      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          final offer = _parse(message, PushOfferSource.openedFromBackground);
          if (offer != null) _opened.add(offer);
        }),
      );

      _subscriptions.add(
        _messaging.onTokenRefresh.listen((token) {
          if (token.isNotEmpty) _tokenRefresh.add(token);
        }),
      );

      return const PushAvailability.available();
    } on Object catch (e) {
      AppLogger.w('FCM unavailable: $e');
      return const PushAvailability.unavailable(
        PushUnavailableReason.unsupported,
      );
    }
  }

  @override
  Future<String?> requestPermissionAndToken() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) {
        AppLogger.w('Notification permission not granted; push is off');
        return null;
      }
      return await _messaging.getToken();
    } on Object catch (e) {
      AppLogger.w('Could not obtain an FCM token: $e');
      return null;
    }
  }

  @override
  Future<String?> currentToken() async {
    try {
      return await _messaging.getToken();
    } on Object catch (e) {
      AppLogger.w('Could not read the FCM token: $e');
      return null;
    }
  }

  @override
  Future<PushOffer?> takeInitialOffer() async {
    if (_initialOfferTaken) return null;
    _initialOfferTaken = true;
    try {
      final message = await _messaging.getInitialMessage();
      if (message == null) return null;
      return _parse(message, PushOfferSource.openedFromTerminated);
    } on Object catch (e) {
      AppLogger.w('Could not read the launch notification: $e');
      return null;
    }
  }

  @override
  Future<void> showOfferNotification(PushOffer offer) async {
    // Android does not display a notification for a message that arrives in
    // the foreground, so without this a driver looking at the map would see
    // nothing until the bottom sheet appeared.
    try {
      await _local.show(
        // The trip id doubles as the notification id, so a second push for
        // the same trip replaces the first rather than stacking.
        id: offer.tripId,
        title: offer.title ?? 'New ride request',
        body: offer.body ?? 'A rider is requesting a trip',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            rideOfferChannel.id,
            rideOfferChannel.name,
            channelDescription: rideOfferChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.call,
            ticker: 'New ride request',
          ),
        ),
        payload: '${offer.tripId}',
      );
    } on Object catch (e) {
      AppLogger.w('Could not show the offer notification: $e');
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } on Object catch (e) {
      // Best effort. The server-side clear is the one that matters, because
      // it is what stops a push being addressed to this device at all.
      AppLogger.w('Could not delete the FCM token: $e');
    }
  }

  PushOffer? _parse(RemoteMessage message, PushOfferSource source) {
    return PushOffer.tryParse(
      message.data,
      source: source,
      title: message.notification?.title,
      body: message.notification?.body,
      sentAt: message.sentTime,
    );
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _foreground.close();
    await _opened.close();
    await _tokenRefresh.close();
  }
}
