/// Keeps the server's idea of this device's push token true.
///
/// THREE MOMENTS, AND WHAT GOES WRONG AT EACH
/// ------------------------------------------
/// **At login.** The app used to send the literal string
/// `'dummy_device_token'` as `device_token`, which the backend dutifully
/// stored. So every driver's row held a token that could never receive
/// anything, and dispatch's own filter -- `if getattr(r.user_id,
/// 'fcm_token', None)` -- counted them as push-capable and queued a message
/// for every one. Worse than sending nothing: sending nothing leaves a
/// previously good token alone, because the login view only writes
/// `fcm_token` when a token is actually supplied.
///
/// **On rotation.** FCM replaces a token on reinstall, on device restore, and
/// after a long idle period. A token the server holds across a rotation is
/// dead, and the only thing that can tell the server otherwise is
/// `onTokenRefresh`. The rider app listens to it and only `debugPrint`s the
/// new value, so a rotated rider token is never re-registered -- recorded
/// here because it is the same defect one app away.
///
/// **At logout.** `POST /auth/logout/` now clears `fcm_token` server-side,
/// which is the half that matters: it stops dispatch addressing this handset.
/// This class deletes the local token as well, so the install stops holding a
/// credential for a session that has ended. The two halves are independent on
/// purpose -- a driver logging out with no signal still gets the local
/// deletion, and a server-side clear does not depend on the client being
/// reachable.
library;

import 'dart:async';

import 'package:dio/dio.dart';

import '../network/api_endpoints.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';
import 'push_transport.dart';

class PushRegistrar {
  PushRegistrar({
    required PushTransport transport,
    required DioClient dioClient,
  }) : _transport = transport,
       _dioClient = dioClient;

  final PushTransport _transport;
  final DioClient _dioClient;

  StreamSubscription<String>? _refreshSub;
  PushAvailability _availability = const PushAvailability.unavailable(
    PushUnavailableReason.notConfigured,
  );

  PushAvailability get availability => _availability;

  /// Start Firebase and begin following token rotations. Never throws.
  Future<PushAvailability> initialize() async {
    _availability = await _transport.initialize();
    if (!_availability.isAvailable) {
      AppLogger.w(
        'Push unavailable (${_availability.reason?.name}); ride offers will '
        'arrive over the dispatch WebSocket only',
      );
      return _availability;
    }

    _refreshSub?.cancel();
    _refreshSub = _transport.onTokenRefresh.listen((token) {
      // Fire and forget: a rotation that cannot be reported now is reported
      // at the next login, which also sends the current token.
      registerToken(token);
    });
    return _availability;
  }

  /// The token to send as `device_token` at login, or null.
  ///
  /// Null is a correct, documented outcome -- no Play Services, permission
  /// declined, Firebase not configured, no network at launch -- and the
  /// caller must omit the field entirely rather than sending a placeholder.
  Future<String?> deviceTokenForLogin() async {
    if (!_availability.isAvailable) return null;
    final token = await _transport.requestPermissionAndToken();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  /// Tell the server about a token obtained outside a login.
  ///
  /// `fcm_token` is write-only on the profile serializer, so `PATCH
  /// /auth/update/` is the supported way to set it. Best effort: a failure
  /// here costs push until the next login, and must never surface to a
  /// driver who did not ask for anything.
  Future<bool> registerToken(String token) async {
    if (token.isEmpty) return false;
    try {
      await _dioClient.dio.patch(
        ApiEndpoints.updateProfile,
        data: {'fcm_token': token},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      // The token itself is never logged: anyone holding one can push to
      // that device.
      AppLogger.i('Push token registered with the server');
      return true;
    } catch (e) {
      AppLogger.w('Could not register the refreshed push token: $e');
      return false;
    }
  }

  /// Drop this install's token at logout.
  ///
  /// The server clears its own copy inside `POST /auth/logout/`; this is the
  /// device half. Never throws -- logout must not depend on it.
  Future<void> clearLocalToken() async {
    try {
      await _transport.deleteToken();
    } catch (e) {
      AppLogger.w('Could not delete the local push token: $e');
    }
  }

  Future<void> dispose() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
  }
}
