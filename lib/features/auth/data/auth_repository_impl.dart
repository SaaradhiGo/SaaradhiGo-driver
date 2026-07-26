import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/storage/token_store.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._tokenStore, this._localStore);

  final ApiClient _api;
  final TokenStore _tokenStore;
  final LocalStore _localStore;

  @override
  Future<void> requestOtp(String phoneNumber) async {
    await _api.post(
      ApiEndpoints.requestOtp,
      // `role` drives profile creation on the server for a first-time user.
      // Sending 'driver' here is what makes this a driver account.
      body: {'phone_number': phoneNumber, 'role': 'driver'},
      skipAuth: true,
    );
  }

  @override
  Future<AuthUser> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? deviceToken,
  }) async {
    final data = await _api.post(
      ApiEndpoints.login,
      body: {
        'phone_number': phoneNumber,
        'otp': otp,
        'role': 'driver',
        'device_token': ?deviceToken,
      },
      skipAuth: true,
    );

    final access = data['access'] as String?;
    final refresh = data['refresh'] as String?;
    if (access == null || access.isEmpty) {
      throw const _AuthContractException(
        'Login succeeded but no token was returned.',
      );
    }
    await _tokenStore.write(access: access, refresh: refresh);

    final userJson = data['user'];
    return userJson is Map<String, dynamic>
        ? AuthUser.fromJson(userJson)
        : await fetchProfile();
  }

  @override
  Future<AuthUser> fetchProfile() async {
    final data = await _api.get(ApiEndpoints.userProfile);
    return AuthUser.fromJson(data);
  }

  @override
  Future<AuthUser> updateProfile({String? fullName, String? email}) async {
    final data = await _api.patch(
      ApiEndpoints.updateUser,
      body: {
        'full_name': ?fullName,
        'email': ?email,
      },
    );
    return AuthUser.fromJson(data.isEmpty ? const {} : data);
  }

  @override
  Future<void> logout() async {
    final refresh = await _tokenStore.readRefresh();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        // Best-effort: the point is to blacklist the refresh token so a
        // stolen copy is dead. If the network is down we still clear locally
        // — leaving a driver signed in on a device they are trying to sign
        // out of is the worse failure.
        await _api.post(ApiEndpoints.logout, body: {'refresh_token': refresh});
      }
    } on Object {
      // Swallowed deliberately; see above.
    } finally {
      await _tokenStore.clear();
      await _localStore.clearSessionState();
    }
  }

  @override
  Future<bool> hasSession() => _tokenStore.hasSession();
}

class _AuthContractException implements Exception {
  const _AuthContractException(this.message);
  final String message;
  @override
  String toString() => message;
}
