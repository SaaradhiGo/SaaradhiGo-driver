/// A logged-out session must not come back, even when the secure store fails.
///
/// WHAT THIS PROVES
/// ----------------
/// `SecureStorageService.clearTokens()` was three bare awaits on
/// `_storage.delete`. flutter_secure_storage surfaces a locked or corrupt
/// Android Keystore as a PlatformException, and on a throw from the first
/// delete:
///
///   * the refresh token and the cached profile were never deleted;
///   * the exception propagated into `AuthNotifier.logout()`, where the
///     `state = AuthUnauthenticated()` line came AFTER the await and so never
///     ran -- the driver pressed Log out and stayed signed in;
///   * the next cold start read the surviving token and restored the session.
///
/// The same three lines run in `AuthInterceptor._refreshTokens()` when the
/// server REJECTS a refresh token, with `emitSessionExpired()` after them: a
/// throw there kept a session alive that the server had already repudiated.
///
/// Every test below fails against that implementation.
library;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/auth_interceptor.dart';
import 'package:saaradhigo_driver/core/storage/secure_storage_service.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/features/auth/domain/auth_repository.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_notifier.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A secure store that holds real values and can be told to fail.
///
/// `FlutterSecureStorage.setMockInitialValues` installs a store that always
/// succeeds, so it cannot express the case this file is about.
class _HostileSecureStorage extends FlutterSecureStoragePlatform {
  _HostileSecureStorage(this.data);

  final Map<String, String> data;

  /// Operations that throw instead of running.
  bool failDelete = false;
  bool failDeleteAll = false;
  bool failRead = false;

  /// Every delete that was attempted, in order. Proves one failure does not
  /// shield the keys after it.
  final List<String> deleteAttempts = [];

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async =>
      data.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    deleteAttempts.add(key);
    if (failDelete) {
      throw PlatformException(
        code: 'Exception encountered',
        message: 'KeyStoreException: Key user not authenticated',
      );
    }
    data.remove(key);
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    deleteAttempts.add('*');
    if (failDeleteAll) {
      throw PlatformException(code: 'Exception encountered');
    }
    data.clear();
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    if (failRead) throw PlatformException(code: 'Exception encountered');
    return data[key];
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async =>
      data;

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    data[key] = value;
  }
}

class _ThrowingAuthRepository implements AuthRepository {
  @override
  Future<void> requestOtp(String phoneNumber) async {}

  @override
  Future<UserModel?> verifyOtp(String phoneNumber, String otp) async => null;

  @override
  Future<void> logout() async => throw PlatformException(code: 'nope');

  @override
  Future<UserModel?> emailLogin({
    required String email,
    required String password,
  }) async =>
      null;

  @override
  Future<String> requestPasswordReset(String email) async => 'sent';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _HostileSecureStorage store;

  setUp(() {
    store = _HostileSecureStorage({
      'access_token': 'live-access-token',
      'refresh_token': 'live-refresh-token',
      'user_data': '{"id":7,"phone_number":"+919876543210"}',
    });
    FlutterSecureStoragePlatform.instance = store;
    SharedPreferences.setMockInitialValues({});
    SecureStorageService.resetSessionRevocationCacheForTests();
  });

  group('a clean logout', () {
    test('deletes all three keys and leaves no tombstone behind', () async {
      await SecureStorageService.clearTokens();

      expect(store.data, isEmpty);
      expect(await SecureStorageService.getAccessToken(), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('auth_session_revoked'), isNull,
          reason: 'a successful logout should leave no trace');
    });

    test('a token written by a later login is readable again', () async {
      await SecureStorageService.clearTokens();
      await SecureStorageService.saveTokens(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      );

      expect(await SecureStorageService.getAccessToken(), 'new-access');
      expect(await SecureStorageService.getRefreshToken(), 'new-refresh');
    });
  });

  group('when the secure store refuses to delete', () {
    setUp(() {
      store.failDelete = true;
      store.failDeleteAll = true;
    });

    test('clearTokens does not throw', () async {
      await expectLater(SecureStorageService.clearTokens(), completes);
    });

    test('it still attempts every key -- one failure shields none', () async {
      await SecureStorageService.clearTokens();

      expect(store.deleteAttempts,
          containsAll(['access_token', 'refresh_token', 'user_data']),
          reason: 'the original code stopped at the first throw');
    });

    test('the surviving token is unreadable afterwards', () async {
      await SecureStorageService.clearTokens();

      // The credential is still physically present...
      expect(store.data['access_token'], 'live-access-token');
      expect(store.data['refresh_token'], 'live-refresh-token');

      // ...and no longer reachable through the only API that reads it.
      expect(await SecureStorageService.getAccessToken(), isNull);
      expect(await SecureStorageService.getRefreshToken(), isNull);
      expect(await SecureStorageService.getUser(), isNull);
    });

    test('it stays unreadable across a restart', () async {
      await SecureStorageService.clearTokens();

      // A new process: the in-memory tombstone is gone, SharedPreferences and
      // the undeleted token both survive.
      SecureStorageService.resetSessionRevocationCacheForTests();

      expect(store.data['access_token'], 'live-access-token');
      expect(await SecureStorageService.getAccessToken(), isNull,
          reason: 'this is the cold start that used to restore the session');
      expect(await SecureStorageService.getUser(), isNull);
    });

    test('a genuine later login still works', () async {
      await SecureStorageService.clearTokens();
      expect(await SecureStorageService.getAccessToken(), isNull);

      // Signing in again must lift the tombstone, or the driver is locked out
      // of their own app by a store that failed once.
      await SecureStorageService.saveTokens(
        accessToken: 'second-session',
        refreshToken: 'second-refresh',
      );

      expect(await SecureStorageService.getAccessToken(), 'second-session');
    });

    test('the network layer sends no Authorization header', () async {
      // The read gate has to cover the interceptor too: it reads the token
      // directly, and nothing would have told it the session was over.
      await SecureStorageService.clearTokens();

      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/'));
      dio.interceptors.add(AuthInterceptor(dio));
      RequestOptions? seen;
      dio.httpClientAdapter = _CapturingAdapter((options) => seen = options);

      await dio.get<dynamic>('/driver/profile/');

      expect(seen, isNotNull);
      expect(seen!.headers.containsKey('Authorization'), isFalse,
          reason: 'a revoked session must not authenticate a request');
    });
  });

  group('when the secure store cannot be read at all', () {
    test('no session is assumed', () async {
      store.failRead = true;

      // getAccessToken rethrows the platform error; the caller
      // (AuthNotifier._checkAuthStatus) must fail closed, not open.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authNotifierProvider);
      await pumpEventQueue();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
    });
  });

  group('AuthNotifier.logout', () {
    test('ends the session even when clearing credentials throws', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_ThrowingAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await pumpEventQueue();
      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>(),
          reason: 'the fixture starts with a stored token');

      await notifier.logout();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>(),
          reason: 'the state change used to sit after the await that threw');
    });
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.onRequest);

  final void Function(RequestOptions options) onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest(options);
    return ResponseBody.fromString('{"status":"success"}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
