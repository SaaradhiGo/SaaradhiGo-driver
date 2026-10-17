/// The seam between this app and Firebase Cloud Messaging.
///
/// WHY AN INTERFACE AND NOT JUST FirebaseMessaging
/// -----------------------------------------------
/// `firebase_messaging` is a platform plugin: in a `flutter test` binding
/// every call throws `MissingPluginException`, and `Firebase.initializeApp()`
/// needs a real `google-services.json`. Written against the plugin directly,
/// none of the logic that matters -- token registration, token refresh,
/// deduplication, stale-offer rejection, logout cleanup -- could be tested at
/// all, and all of it would have to be verified by hand on a phone every time
/// it changed.
///
/// So the plugin lives behind this interface. `FirebasePushTransport` is the
/// thin, untestable glue; `FakePushTransport` in the tests drives every path
/// above it. The division is deliberate: anything that could hide a defect
/// sits above the seam.
library;

import 'push_offer.dart';

/// Why push is not available, when it is not.
enum PushUnavailableReason {
  /// No `google-services.json` was compiled in, so Firebase cannot start.
  /// This is the state of every build until the owner adds the file.
  notConfigured,

  /// Firebase started but the driver declined the notification permission.
  permissionDenied,

  /// Google Play Services missing or too old, or the plugin threw.
  unsupported,
}

class PushAvailability {
  const PushAvailability.available() : reason = null;
  const PushAvailability.unavailable(this.reason);

  final PushUnavailableReason? reason;

  bool get isAvailable => reason == null;
}

abstract class PushTransport {
  /// Start Firebase. Never throws; reports why when it cannot.
  Future<PushAvailability> initialize();

  /// Ask for the notification permission (Android 13+ POST_NOTIFICATIONS)
  /// and return the device token, or null when it cannot be obtained.
  Future<String?> requestPermissionAndToken();

  /// The current token without prompting, or null.
  Future<String?> currentToken();

  /// FCM rotates tokens: on app restore to a new device, on reinstall, after
  /// a long idle period. A token the server holds after a rotation is dead,
  /// and nothing tells the server that except this stream.
  Stream<String> get onTokenRefresh;

  /// Offers that arrived while the app was in the foreground.
  Stream<PushOffer> get onForegroundOffer;

  /// Offers whose notification the driver tapped while the app was
  /// backgrounded.
  Stream<PushOffer> get onOpenedOffer;

  /// The offer whose notification launched the app from terminated, if any.
  /// Consumed once.
  Future<PushOffer?> takeInitialOffer();

  /// Show a heads-up notification for an offer that arrived in the
  /// foreground. Android does not display those automatically.
  Future<void> showOfferNotification(PushOffer offer);

  /// Invalidate the device token at logout, so a push for the next driver to
  /// use this phone cannot be delivered against the previous session.
  Future<void> deleteToken();

  Future<void> dispose();
}
