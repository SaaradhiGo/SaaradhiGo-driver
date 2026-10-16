/// The token key names the backend actually sends.
///
/// THE DEFECT THIS LOCKS DOWN
/// --------------------------
/// `auth_repository_impl.verifyOtp` read `data['access']` and
/// `data['refresh']`. The backend sends `token` and `refresh_token`:
///
///     servers/auth_user/views.py  login    -> {token, refresh_token, user}
///     servers/auth_user/views.py  refresh  -> {token, refresh_token}
///
/// So `verifyOtp` always threw "Login succeeded but no token was returned."
/// and the refresh interceptor always failed, meaning **no driver could sign
/// in with this build**, and any session that somehow started died after the
/// 15-minute access-token lifetime.
///
/// Nothing caught it. `flutter analyze` cannot see an API contract, and the
/// existing unit tests built their own fixtures using the same wrong key
/// names the code used — so the tests and the code agreed with each other and
/// both disagreed with the server.
///
/// These tests therefore use the EXACT envelope copied from the backend view,
/// which is the only version of this assertion that is worth anything.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_client.dart';
import 'package:saaradhigo_driver/core/storage/local_store.dart';
import 'package:saaradhigo_driver/features/auth/data/auth_repository_impl.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  group('readTokenPair', () {
    test('reads the keys the backend actually sends', () {
      // Copied from servers/auth_user/views.py.
      final pair = readTokenPair({
        'token': 'access-value',
        'refresh_token': 'refresh-value',
        'user': {'id': 1},
      });

      expect(pair.access, 'access-value');
      expect(pair.refresh, 'refresh-value');
    });

    test('still reads the short aliases, if the server ever adds them', () {
      final pair = readTokenPair({'access': 'a', 'refresh': 'r'});
      expect(pair.access, 'a');
      expect(pair.refresh, 'r');
    });

    test('prefers the real key when both are present', () {
      final pair = readTokenPair({
        'token': 'real', 'access': 'alias',
        'refresh_token': 'real-r', 'refresh': 'alias-r',
      });
      expect(pair.access, 'real');
      expect(pair.refresh, 'real-r');
    });

    test('an empty string is not a token', () {
      // An empty access token would otherwise be stored and every subsequent
      // request would send `Bearer ` and 401.
      final pair = readTokenPair({'token': '', 'refresh_token': ''});
      expect(pair.access, isNull);
      expect(pair.refresh, isNull);
    });

    test('a missing or null body yields no tokens rather than throwing', () {
      expect(readTokenPair(null).access, isNull);
      expect(readTokenPair({}).access, isNull);
      expect(readTokenPair({'token': 42}).access, isNull);
    });
  });

  group('verifyOtp against the real envelope', () {
    late FakeHttpAdapter adapter;
    late FakeTokenStore tokens;
    late AuthRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      adapter = FakeHttpAdapter();
      tokens = FakeTokenStore();
      repository = AuthRepositoryImpl(
        ApiClient(tokens, dio: Dio()..httpClientAdapter = adapter),
        tokens,
        // A real LocalStore over mocked SharedPreferences, as
        // trip_lifecycle_test does: it is a concrete class, so a fake would
        // have to re-implement it for no benefit.
        await LocalStore.create(),
      );
    });

    test('stores the token from a real login response', () async {
      adapter.enqueue(body: {
        'status': 'success',
        'data': {
          'token': 'access-1',
          'refresh_token': 'refresh-1',
          'user': {
            'id': 7,
            'phone_number': '+919999000002',
            'full_name': 'Test Driver',
            'role': 'driver',
          },
        },
      });

      final user = await repository.verifyOtp(
        phoneNumber: '+919999000002', otp: '100002',
      );

      expect(user.role, 'driver');
      // The actual regression: before the fix this threw instead.
      expect(tokens.access, 'access-1');
      expect(tokens.refresh, 'refresh-1');
    });

    test('a response with no token is a clear failure, not a blank session',
        () async {
      adapter.enqueue(body: {'status': 'success', 'data': {'user': {}}});

      await expectLater(
        repository.verifyOtp(phoneNumber: '+919999000002', otp: '100002'),
        throwsA(anything),
      );
      expect(tokens.access, isNull);
    });
  });

  group('email login', () {
    late FakeHttpAdapter adapter;
    late FakeTokenStore tokens;
    late AuthRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      adapter = FakeHttpAdapter();
      tokens = FakeTokenStore();
      repository = AuthRepositoryImpl(
        ApiClient(tokens, dio: Dio()..httpClientAdapter = adapter),
        tokens,
        // A real LocalStore over mocked SharedPreferences, as
        // trip_lifecycle_test does: it is a concrete class, so a fake would
        // have to re-implement it for no benefit.
        await LocalStore.create(),
      );
    });

    test('posts to the email endpoint and stores the token', () async {
      adapter.enqueue(body: {
        'status': 'success',
        'data': {
          'token': 'access-2',
          'refresh_token': 'refresh-2',
          'user': {
            'id': 8,
            'phone_number': '+919999000002',
            'role': 'driver',
          },
        },
      });

      await repository.emailLogin(
        email: 'driver@example.test', password: 'Cadence-Harbour-74',
      );

      final request = adapter.requests.single;
      expect(request.path, '/auth/email/login/');
      final body = (request.data as Map).cast<String, dynamic>();
      expect(body['email'], 'driver@example.test');
      expect(body['password'], 'Cadence-Harbour-74');
      // Absent, not null: a driver is never asked for a second factor.
      expect(body.containsKey('mfa_code'), isFalse);
      expect(tokens.access, 'access-2');
    });

    test('a reset request sends only the address', () async {
      adapter.enqueue(body: {'status': 'success', 'data': {}});

      await repository.requestPasswordReset('driver@example.test');

      final request = adapter.requests.single;
      expect(request.path, '/auth/password/forgot/');
      expect((request.data as Map)['email'], 'driver@example.test');
    });
  });
}
