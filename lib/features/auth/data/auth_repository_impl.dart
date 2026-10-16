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

    final tokens = readTokenPair(data);
    if (tokens.access == null) {
      throw const _AuthContractException(
        'Login succeeded but no token was returned.',
      );
    }
    await _tokenStore.write(access: tokens.access!, refresh: tokens.refresh);

    final userJson = data['user'];
    return userJson is Map<String, dynamic>
        ? AuthUser.fromJson(userJson)
        : await fetchProfile();
  }

  @override
  Future<AuthUser> emailLogin({
    required String email,
    required String password,
    String? mfaCode,
  }) async {
    final data = await _api.post(
      ApiEndpoints.emailLogin,
      body: {
        'email': email,
        'password': password,
        'mfa_code': ?mfaCode,
      },
      skipAuth: true,
    );

    final tokens = readTokenPair(data);
    if (tokens.access == null) {
      throw const _AuthContractException(
        'Sign-in succeeded but no token was returned.',
      );
    }
    await _tokenStore.write(access: tokens.access!, refresh: tokens.refresh);

    final userJson = data['user'];
    return userJson is Map<String, dynamic>
        ? AuthUser.fromJson(userJson)
        : await fetchProfile();
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    // The server answers 200 with the same message for every address, so
    // there is nothing to branch on and nothing to report back beyond "the
    // request was accepted".
    await _api.post(
      ApiEndpoints.passwordForgot,
      body: {'email': email},
      skipAuth: true,
    );
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

/// Pull the access/refresh pair out of an auth response.
///
/// THE DEFECT THIS FIXES
/// ---------------------
/// This app read `data['access']` and `data['refresh']`. The backend returns
/// `token` and `refresh_token` (see `servers/auth_user/views.py` — the login
/// response is `{'token', 'refresh_token', 'user'}` and the refresh response
/// is `{'token', 'refresh_token'}`).
///
/// So `verifyOtp` always threw "Login succeeded but no token was returned."
/// and the refresh interceptor always failed silently. **No driver could sign
/// in with this build at all**, and nothing caught it: the unit tests used
/// their own fixtures with the wrong key names, and `flutter analyze` cannot
/// see an API contract.
///
/// Both spellings are accepted so the app keeps working if the server ever
/// adds the shorter aliases, but `token`/`refresh_token` is what it sends
/// today and is what the tests pin.
({String? access, String? refresh}) readTokenPair(Map<String, dynamic>? data) {
  if (data == null) return (access: null, refresh: null);
  String? pick(List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  return (
    access: pick(['token', 'access', 'access_token']),
    refresh: pick(['refresh_token', 'refresh']),
  );
}
