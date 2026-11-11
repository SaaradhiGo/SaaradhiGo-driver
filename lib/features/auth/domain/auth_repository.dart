import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/notifications/push_providers.dart';
import '../../../../domain/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final registrar = ref.watch(pushRegistrarProvider);
  return AuthRepository(
    dioClient,
    deviceTokenReader: registrar.deviceTokenForLogin,
    onSessionEnded: registrar.clearLocalToken,
  );
});

class AuthRepository {
  final DioClient _dioClient;

  /// The FCM token for this device, or null when push is unavailable.
  ///
  /// Injected rather than reached for, because `firebase_messaging` throws
  /// `MissingPluginException` under `flutter test` -- so a repository that
  /// called it directly could not be tested at all.
  final Future<String?> Function()? _deviceTokenReader;

  /// Runs when the session ends, to drop this install's push token.
  final Future<void> Function()? _onSessionEnded;

  AuthRepository(
    this._dioClient, {
    Future<String?> Function()? deviceTokenReader,
    Future<void> Function()? onSessionEnded,
  }) : _deviceTokenReader = deviceTokenReader,
       _onSessionEnded = onSessionEnded;

  /// The login body, with `device_token` present only when there is a real
  /// one to send.
  ///
  /// This used to hard-code `'device_token': 'dummy_device_token'`, which the
  /// backend stored verbatim. Every driver row then held a token that could
  /// never receive anything, while dispatch's filter -- `if
  /// getattr(r.user_id, 'fcm_token', None)` -- counted them as push-capable
  /// and queued a message for each. Omitting the key is strictly better: the
  /// login view only writes `fcm_token` when one is supplied, so a login
  /// without push leaves a previously good token alone.
  Future<Map<String, dynamic>> _withDeviceToken(
    Map<String, dynamic> body,
  ) async {
    final reader = _deviceTokenReader;
    if (reader == null) return body;
    try {
      final token = await reader();
      if (token != null && token.isNotEmpty) {
        return {...body, 'device_token': token};
      }
    } catch (e) {
      // Push registration must never be able to fail a login.
      AppLogger.w('Could not read a device token for login: $e');
    }
    return body;
  }

  Future<void> requestOtp(String phoneNumber) async {
    try {
      final responseData = await _dioClient.request(
        () => _dioClient.dio.post(
          ApiEndpoints.requestOtp,
          data: {'phone_number': phoneNumber, 'role': 'driver'},
        ),
      );

      if (responseData['status'] != 'success') {
        throw Exception(responseData['message'] ?? 'Failed to request OTP');
      }
    } on Failure {
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<UserModel?> verifyOtp(String phoneNumber, String otp) async {
    try {
      final responseData = await _dioClient.request(
        () async => _dioClient.dio.post(
          ApiEndpoints.login,
          data: await _withDeviceToken({
            'phone_number': phoneNumber,
            'otp': otp,
          }),
        ),
      );

      if (responseData['status'] == 'success') {
        return await _persistSession(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to verify OTP');
      }
    } on Failure {
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Email + password login.
  ///
  /// The server returns the SAME envelope as phone + OTP -- `data.token`,
  /// `data.refresh_token`, `data.user` -- which is what lets one session layer
  /// serve both. That is asserted against the server's own captured output in
  /// test/auth_contract_conformance_test.dart rather than assumed here.
  Future<UserModel?> emailLogin({
    required String email,
    required String password,
  }) async {
    try {
      final responseData = await _dioClient.request(
        () async => _dioClient.dio.post(
          ApiEndpoints.emailLogin,
          data: await _withDeviceToken({'email': email, 'password': password}),
        ),
      );

      if (responseData['status'] == 'success') {
        return await _persistSession(responseData);
      }
      throw Exception(_messageFrom(responseData) ?? 'Could not sign in');
    } on Failure {
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Asks for a reset link. Always succeeds server-side, by design: a
  /// different answer for a known and an unknown address would let anyone
  /// enumerate driver accounts.
  Future<String> requestPasswordReset(String email) async {
    try {
      final responseData = await _dioClient.request(
        () => _dioClient.dio.post(
          ApiEndpoints.passwordForgot,
          data: {'email': email},
        ),
      );
      final data = responseData['data'];
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'If that address belongs to an account, we have sent a link to '
          'it. Check your inbox, including spam.';
    } on Failure {
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Ends the session on the server, then locally.
  ///
  /// The server call is best-effort and deliberately first: without it the
  /// refresh token stays valid for its full lifetime, so a copy taken off a
  /// lost phone still mints access tokens long after the driver pressed Log
  /// out. A driver with no signal must still be able to log out, though, so a
  /// failure here is logged and ignored -- the local clear is what the UI
  /// depends on, and it cannot throw.
  Future<void> logout() async {
    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dioClient.dio.post(
          ApiEndpoints.logout,
          data: {'refresh_token': refreshToken},
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      AppLogger.w('Server-side logout did not complete; clearing locally', e);
    }

    // Drop this install's push token. `POST /auth/logout/` clears the
    // server's copy, which is the half that stops dispatch addressing this
    // handset; this is the device half, and it runs even when the call above
    // failed -- a driver with no signal still ends their session completely.
    final onSessionEnded = _onSessionEnded;
    if (onSessionEnded != null) {
      try {
        await onSessionEnded();
      } catch (e) {
        AppLogger.w('Could not clear the local push token at logout', e);
      }
    }

    await SecureStorageService.clearTokens();
  }

  /// Stores the token pair and profile from a successful login envelope.
  Future<UserModel?> _persistSession(Map<String, dynamic> responseData) async {
    final data = responseData['data'];
    if (data is! Map) {
      throw Exception('The server returned no session data');
    }

    final token = data['token'];
    final refreshToken = data['refresh_token'];
    if (token is! String ||
        token.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      // Never leave a half-session behind: no token means not signed in.
      throw Exception('The server returned an incomplete session');
    }

    final userRaw = data['user'];
    UserModel? user;
    if (userRaw != null && userRaw is Map<String, dynamic>) {
      user = UserModel.fromJson(userRaw);
      await SecureStorageService.saveUser(user);
    }

    await SecureStorageService.saveTokens(
      accessToken: token,
      refreshToken: refreshToken,
    );

    return user;
  }

  /// The server's own message for a refusal, without inventing one.
  String? _messageFrom(Map<String, dynamic> responseData) {
    final error = responseData['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    final message = responseData['message'];
    return message is String ? message : null;
  }
}
