import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user_model.dart';
import '../utils/app_logger.dart';

/// Token and profile storage, and the one rule it must never break:
/// **a session that has been ended cannot come back.**
///
/// THE DEFECT THIS CLOSES
/// ----------------------
/// `clearTokens()` was three bare awaits:
///
///     await _storage.delete(key: _keyAccessToken);
///     await _storage.delete(key: _keyRefreshToken);
///     await _storage.delete(key: _keyUserData);
///
/// If the first one threw -- a locked keystore, a corrupt entry, a Keystore
/// error after an OS update, all of which flutter_secure_storage surfaces as
/// a PlatformException -- then:
///
///   * the remaining two never ran, so the refresh token and the cached
///     profile stayed on disk;
///   * the exception propagated out of `AuthRepository.logout()` into
///     `AuthNotifier.logout()`, where `state = AuthUnauthenticated()` sat on
///     the line AFTER the await and so never executed. The driver tapped Log
///     out, saw an error, and was still signed in;
///   * on the next cold start `_checkAuthStatus()` read the surviving token
///     and restored the session, profile and all.
///
/// The same path runs inside `AuthInterceptor._refreshTokens()`: when the
/// server rejects a refresh token it calls `clearTokens()` and then emits
/// `sessionExpired`. A throw there skipped the event, so a session the server
/// had already repudiated stayed live in the app.
///
/// HOW IT IS CLOSED
/// ----------------
/// 1. `clearTokens()` never throws and attempts all three deletions
///    independently, so one failure cannot shield the others.
/// 2. Ending a session sets a revocation tombstone, and every read returns
///    null while it is set. A token that could not be deleted therefore
///    cannot be used or restored -- the gate is on the read, so it covers
///    `AuthInterceptor` and `AuthNotifier` alike without either having to
///    remember.
/// 3. The tombstone is held in memory AND in SharedPreferences -- a different
///    store from the one that is failing. In memory it is authoritative for
///    the rest of the process; in SharedPreferences it survives a restart.
/// 4. A successful `saveTokens()` lifts it, so a fresh login works normally.
///
/// Residual risk, stated rather than hidden: if the secure store AND
/// SharedPreferences are both unwritable, the tombstone cannot outlive the
/// process and a restart would read the surviving token. Nothing in the app
/// can do better than that, because there is then nowhere left to record the
/// fact. Within a running process the guarantee holds unconditionally.
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserData = 'user_data';

  /// Set when a session has been ended but the store could not be proven
  /// empty. Never holds a credential -- only the fact that one is void.
  static const _keySessionRevoked = 'auth_session_revoked';

  /// Authoritative for this process. Null until first consulted.
  static bool? _revoked;

  static Future<bool> _isRevoked() async {
    final cached = _revoked;
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      return _revoked = prefs.getBool(_keySessionRevoked) ?? false;
    } catch (e) {
      // Cannot read the tombstone. Do NOT assume a live session: an
      // unreadable tombstone is exactly the case it exists for.
      AppLogger.e('Could not read the session revocation flag', e);
      return _revoked = true;
    }
  }

  static Future<void> _setRevoked(bool value) async {
    _revoked = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool(_keySessionRevoked, true);
      } else {
        await prefs.remove(_keySessionRevoked);
      }
    } catch (e) {
      // In-memory state still holds for the rest of this process.
      AppLogger.e('Could not persist the session revocation flag', e);
    }
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    // Only after both writes succeeded: a half-written pair must stay
    // unreadable rather than become a session.
    await _setRevoked(false);
  }

  static Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _keyUserData, value: jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    if (await _isRevoked()) return null;
    final str = await _storage.read(key: _keyUserData);
    if (str == null || str.isEmpty) return null;
    try {
      final json = jsonDecode(str);
      if (json is Map<String, dynamic>) {
        return UserModel.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAccessToken() async {
    if (await _isRevoked()) return null;
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    if (await _isRevoked()) return null;
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Ends the session. Never throws.
  ///
  /// Callers must be able to end a session unconditionally -- there is no
  /// useful way for a UI or an interceptor to handle "logout failed", and
  /// leaving the user signed in is the one outcome that is never acceptable.
  static Future<void> clearTokens() async {
    // Tombstone FIRST. Everything after this point may fail; from here on the
    // session is void regardless of what the store does.
    await _setRevoked(true);

    var allDeleted = true;
    for (final key in const [_keyAccessToken, _keyRefreshToken, _keyUserData]) {
      try {
        await _storage.delete(key: key);
      } catch (e) {
        allDeleted = false;
        AppLogger.e('Could not delete "$key" from secure storage', e);
      }
    }

    if (!allDeleted) {
      // One more attempt, through a different plugin call: deleteAll can
      // succeed where a per-key delete fails on a corrupt entry.
      try {
        await _storage.deleteAll();
        allDeleted = true;
      } catch (e) {
        AppLogger.e('deleteAll also failed; the tombstone stands', e);
      }
    }

    if (allDeleted) {
      // Nothing left to protect, so leave no trace behind.
      await _setRevoked(false);
    }
  }

  /// Test seam. Resets the in-memory tombstone so each test starts clean.
  static void resetSessionRevocationCacheForTests() => _revoked = null;
}
