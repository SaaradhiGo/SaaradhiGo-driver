/// The device token's life in this app: obtained, sent, rotated, dropped.
///
/// THE DEFECT THIS REPLACES
/// ------------------------
/// The app sent the literal string `'dummy_device_token'` as `device_token`
/// at every login, and the backend stored it. So every driver row held a
/// token that could never receive anything, while dispatch's own filter --
/// `if getattr(r.user_id, 'fcm_token', None)` -- counted those drivers as
/// push-capable and queued an FCM message for each of them.
///
/// Sending nothing is strictly better than sending a placeholder: the login
/// view only writes `fcm_token` when a token is supplied, so a login from a
/// device that cannot produce one leaves a previously good token alone.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/core/network/dio_client.dart';
import 'package:saaradhigo_driver/core/notifications/push_registrar.dart';
import 'package:saaradhigo_driver/core/notifications/push_transport.dart';
import 'package:saaradhigo_driver/core/storage/secure_storage_service.dart';
import 'package:saaradhigo_driver/features/auth/domain/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_push_transport.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int statusCode = 200;
  Map<String, dynamic> body = const {'status': 'success', 'data': {}};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  Map<String, dynamic> bodyOf(RequestOptions options) =>
      (options.data as Map).cast<String, dynamic>();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePushTransport transport;
  late _RecordingAdapter adapter;
  late DioClient client;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    SecureStorageService.resetSessionRevocationCacheForTests();
    transport = FakePushTransport();
    adapter = _RecordingAdapter();
    client = DioClient();
    client.dio.httpClientAdapter = adapter;
  });

  PushRegistrar registrar({PushTransport? override}) =>
      PushRegistrar(transport: override ?? transport, dioClient: client);

  group('obtaining a token', () {
    test('a configured device yields one, after asking permission', () async {
      final push = registrar();
      await push.initialize();

      final token = await push.deviceTokenForLogin();

      expect(token, 'fake-fcm-token');
      expect(
        transport.permissionRequests,
        1,
        reason: 'Android 13+ needs POST_NOTIFICATIONS to be requested',
      );
    });

    test('a declined permission yields null, not a placeholder', () async {
      transport.permissionGranted = false;
      final push = registrar();
      await push.initialize();

      expect(await push.deviceTokenForLogin(), isNull);
    });

    test('an unconfigured build yields null without even asking', () async {
      // No google-services.json: the state of every build until the owner
      // adds the file. Push is simply off; the socket carries dispatch.
      transport.availability = const PushAvailability.unavailable(
        PushUnavailableReason.notConfigured,
      );
      final push = registrar();
      await push.initialize();

      expect(await push.deviceTokenForLogin(), isNull);
      expect(transport.permissionRequests, 0);
    });

    test('a broken Play Services install cannot take the app down', () async {
      final push = registrar(override: HostilePushTransport());

      await expectLater(push.initialize(), completes);
      expect(await push.deviceTokenForLogin(), isNull);
      await expectLater(push.clearLocalToken(), completes);
    });
  });

  group('registering a rotated token', () {
    test('a refresh is PATCHed to /auth/update/ as fcm_token', () async {
      // FCM rotates on reinstall, device restore and long idle periods. A
      // token the server holds across a rotation is dead, and onTokenRefresh
      // is the only thing that can say so.
      final push = registrar();
      await push.initialize();

      transport.refresh.add('rotated-token-aaa');
      await pumpEventQueue();

      final patches = adapter.requests
          .where((r) => r.path == ApiEndpoints.updateProfile)
          .toList();
      expect(patches, hasLength(1));
      expect(patches.single.method, 'PATCH');
      expect(adapter.bodyOf(patches.single), {
        'fcm_token': 'rotated-token-aaa',
      });
    });

    test('an empty token is not sent', () async {
      final push = registrar();
      await push.initialize();

      expect(await push.registerToken(''), isFalse);
      expect(adapter.requests, isEmpty);
    });

    test('a failed registration is swallowed', () async {
      // It costs push until the next login, which also sends the current
      // token. It must never surface to a driver who did not ask for
      // anything.
      adapter.statusCode = 500;
      final push = registrar();
      await push.initialize();

      expect(await push.registerToken('rotated-token-bbb'), isFalse);
    });

    test('nothing is registered when push never initialised', () async {
      transport.availability = const PushAvailability.unavailable(
        PushUnavailableReason.notConfigured,
      );
      final push = registrar();
      await push.initialize();

      transport.refresh.add('rotated-token-ccc');
      await pumpEventQueue();

      expect(adapter.requests, isEmpty);
    });
  });

  group('login sends the real token, or none', () {
    test('a real token is sent as device_token', () async {
      final push = registrar();
      await push.initialize();
      final repository = AuthRepository(
        client,
        deviceTokenReader: push.deviceTokenForLogin,
      );
      adapter.body = {
        'status': 'success',
        'data': {'token': 'a', 'refresh_token': 'r'},
      };

      await repository.verifyOtp('+919876543210', '1234');

      final login = adapter.requests.firstWhere(
        (r) => r.path == ApiEndpoints.login,
      );
      expect(adapter.bodyOf(login)['device_token'], 'fake-fcm-token');
    });

    test('the key is OMITTED when there is no token', () async {
      // Not sent as null, not sent as a placeholder: absent. The login view
      // only writes fcm_token when the key is present, so an absent key
      // preserves whatever good token the server already had.
      transport.permissionGranted = false;
      final push = registrar();
      await push.initialize();
      final repository = AuthRepository(
        client,
        deviceTokenReader: push.deviceTokenForLogin,
      );
      adapter.body = {
        'status': 'success',
        'data': {'token': 'a', 'refresh_token': 'r'},
      };

      await repository.verifyOtp('+919876543210', '1234');

      final login = adapter.requests.firstWhere(
        (r) => r.path == ApiEndpoints.login,
      );
      expect(adapter.bodyOf(login).containsKey('device_token'), isFalse);
    });

    test('no login ever sends the old placeholder', () async {
      final push = registrar();
      await push.initialize();
      final repository = AuthRepository(
        client,
        deviceTokenReader: push.deviceTokenForLogin,
      );
      adapter.body = {
        'status': 'success',
        'data': {'token': 'a', 'refresh_token': 'r'},
      };

      await repository.verifyOtp('+919876543210', '1234');
      await repository.emailLogin(
        email: 'driver@example.test',
        password: 'secret',
      );

      for (final request in adapter.requests) {
        expect(jsonEncode(request.data), isNot(contains('dummy_device_token')));
      }
    });

    test('email login sends it too', () async {
      final push = registrar();
      await push.initialize();
      final repository = AuthRepository(
        client,
        deviceTokenReader: push.deviceTokenForLogin,
      );
      adapter.body = {
        'status': 'success',
        'data': {'token': 'a', 'refresh_token': 'r'},
      };

      await repository.emailLogin(
        email: 'driver@example.test',
        password: 'secret',
      );

      final login = adapter.requests.firstWhere(
        (r) => r.path == ApiEndpoints.emailLogin,
      );
      expect(adapter.bodyOf(login)['device_token'], 'fake-fcm-token');
    });

    test('a token reader that throws cannot fail the login', () async {
      final repository = AuthRepository(
        client,
        deviceTokenReader: () async => throw StateError('play services gone'),
      );
      adapter.body = {
        'status': 'success',
        'data': {'token': 'a', 'refresh_token': 'r'},
      };

      await expectLater(
        repository.verifyOtp('+919876543210', '1234'),
        completes,
      );
      expect(await SecureStorageService.getAccessToken(), 'a');
    });
  });

  group('logout drops the device token', () {
    test('the local token is deleted', () async {
      final push = registrar();
      await push.initialize();
      final repository = AuthRepository(
        client,
        onSessionEnded: push.clearLocalToken,
      );
      await SecureStorageService.saveTokens(
        accessToken: 'a',
        refreshToken: 'r',
      );

      await repository.logout();

      expect(transport.deleteTokenCalls, 1);
      expect(transport.token, isNull);
    });

    test('it is deleted even when the server call fails', () async {
      // A driver with no signal must still end their session completely.
      adapter.statusCode = 503;
      final push = registrar();
      await push.initialize();
      final repository = AuthRepository(
        client,
        onSessionEnded: push.clearLocalToken,
      );
      await SecureStorageService.saveTokens(
        accessToken: 'a',
        refreshToken: 'r',
      );

      await repository.logout();

      expect(transport.deleteTokenCalls, 1);
      expect(await SecureStorageService.getAccessToken(), isNull);
    });

    test('a failing deletion cannot block the logout', () async {
      final repository = AuthRepository(
        client,
        onSessionEnded: () async => throw StateError('keystore angry'),
      );
      await SecureStorageService.saveTokens(
        accessToken: 'a',
        refreshToken: 'r',
      );

      await expectLater(repository.logout(), completes);
      expect(
        await SecureStorageService.getAccessToken(),
        isNull,
        reason: 'the session must end regardless',
      );
    });
  });
}
