/// A [PushTransport] that behaves like FCM without being it.
///
/// `firebase_messaging` throws `MissingPluginException` in a test binding and
/// `Firebase.initializeApp()` needs a real `google-services.json`, so every
/// path above the transport -- token registration, rotation, deduplication,
/// stale rejection, logout cleanup, offer navigation -- would be untestable
/// without this.
library;

import 'dart:async';

import 'package:saaradhigo_driver/core/notifications/push_offer.dart';
import 'package:saaradhigo_driver/core/notifications/push_transport.dart';

class FakePushTransport implements PushTransport {
  FakePushTransport({
    this.availability = const PushAvailability.available(),
    this.token = 'fake-fcm-token',
    this.permissionGranted = true,
  });

  PushAvailability availability;

  /// The token `getToken()` would return. Null models a device that cannot
  /// produce one — no Play Services, no network at launch.
  String? token;

  /// False models a driver who declined the notification permission.
  bool permissionGranted;

  PushOffer? initialOffer;

  final foreground = StreamController<PushOffer>.broadcast();
  final opened = StreamController<PushOffer>.broadcast();
  final refresh = StreamController<String>.broadcast();

  // What the code under test actually did.
  int initializeCalls = 0;
  int permissionRequests = 0;
  int deleteTokenCalls = 0;
  int initialOfferReads = 0;
  final List<PushOffer> shownNotifications = [];

  @override
  Stream<PushOffer> get onForegroundOffer => foreground.stream;

  @override
  Stream<PushOffer> get onOpenedOffer => opened.stream;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Future<PushAvailability> initialize() async {
    initializeCalls++;
    return availability;
  }

  @override
  Future<String?> requestPermissionAndToken() async {
    permissionRequests++;
    if (!permissionGranted) return null;
    return token;
  }

  @override
  Future<String?> currentToken() async => token;

  @override
  Future<PushOffer?> takeInitialOffer() async {
    initialOfferReads++;
    final offer = initialOffer;
    // FCM hands the launch message over exactly once.
    initialOffer = null;
    return offer;
  }

  @override
  Future<void> showOfferNotification(PushOffer offer) async {
    shownNotifications.add(offer);
  }

  @override
  Future<void> deleteToken() async {
    deleteTokenCalls++;
    token = null;
  }

  @override
  Future<void> dispose() async {
    await foreground.close();
    await opened.close();
    await refresh.close();
  }
}

/// A transport whose every call throws, modelling a broken Play Services
/// install. Nothing above it may propagate the failure.
class HostilePushTransport implements PushTransport {
  @override
  Future<PushAvailability> initialize() async =>
      const PushAvailability.unavailable(PushUnavailableReason.unsupported);

  @override
  Future<String?> requestPermissionAndToken() async =>
      throw StateError('play services missing');

  @override
  Future<String?> currentToken() async =>
      throw StateError('play services missing');

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushOffer> get onForegroundOffer => const Stream.empty();

  @override
  Stream<PushOffer> get onOpenedOffer => const Stream.empty();

  @override
  Future<PushOffer?> takeInitialOffer() async =>
      throw StateError('play services missing');

  @override
  Future<void> showOfferNotification(PushOffer offer) async =>
      throw StateError('play services missing');

  @override
  Future<void> deleteToken() async => throw StateError('play services missing');

  @override
  Future<void> dispose() async {}
}
