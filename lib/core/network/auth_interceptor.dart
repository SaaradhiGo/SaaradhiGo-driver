import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'auth_session_events.dart';
import '../utils/app_logger.dart';

class AuthInterceptor extends Interceptor {
  static const _refreshAttemptedExtra = 'auth_refresh_attempted';
  static const _skipRefreshExtra = 'auth_skip_refresh';

  /// Endpoints where a 401 means "those credentials are wrong", not "your
  /// session ended".
  ///
  /// Only `/auth/login/` was excluded. A rejected email login therefore ran
  /// the refresh path: with no stored refresh token that clears the session
  /// and emits sessionExpired, so a driver who mistyped their password was
  /// told "Your session has expired. Please log in again." on the login
  /// screen -- and, now that clearing sets a revocation tombstone, it would
  /// also void a session they still had in another tab of the app.
  static const _unauthenticatedPaths = <String>{
    ApiEndpoints.login,
    ApiEndpoints.emailLogin,
    ApiEndpoints.requestOtp,
    ApiEndpoints.passwordForgot,
  };

  final Dio _dio;
  Future<_TokenPair?>? _refreshFuture;

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_skipRefreshExtra] == true) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }

    final accessToken = await SecureStorageService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final statusCode = err.response?.statusCode;
    final isRefreshRequest = requestOptions.path == ApiEndpoints.refreshToken;
    final hasAlreadyRefreshed =
        requestOptions.extra[_refreshAttemptedExtra] == true;

    if (statusCode != 401 ||
        _unauthenticatedPaths.contains(requestOptions.path) ||
        isRefreshRequest ||
        requestOptions.extra[_skipRefreshExtra] == true ||
        hasAlreadyRefreshed) {
      handler.next(err);
      return;
    }

    final requestAccessToken = _bearerTokenFrom(requestOptions.headers);
    final storedAccessToken = await SecureStorageService.getAccessToken();
    final String? accessToken;
    if (storedAccessToken != null &&
        storedAccessToken.isNotEmpty &&
        storedAccessToken != requestAccessToken) {
      // Another request refreshed the session before this 401 was processed.
      accessToken = storedAccessToken;
    } else {
      accessToken = await _getRefreshedAccessToken();
    }

    if (accessToken == null) {
      handler.next(err);
      return;
    }

    final retryHeaders = Map<String, dynamic>.from(requestOptions.headers)
      ..['Authorization'] = 'Bearer $accessToken';
    final retryExtra = Map<String, dynamic>.from(requestOptions.extra)
      ..[_refreshAttemptedExtra] = true;
    final retryOptions = requestOptions.copyWith(
      headers: retryHeaders,
      extra: retryExtra,
    );

    try {
      final retryResponse = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  String? _bearerTokenFrom(Map<String, dynamic> headers) {
    final authorization = headers.entries
        .where((entry) => entry.key.toLowerCase() == 'authorization')
        .map((entry) => entry.value)
        .whereType<String>()
        .firstOrNull;
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return null;
    }
    return authorization.substring('Bearer '.length);
  }

  Future<String?> _getRefreshedAccessToken() async {
    final currentRefresh = _refreshFuture;
    if (currentRefresh != null) {
      return (await currentRefresh)?.accessToken;
    }

    final refreshFuture = _refreshTokens();
    _refreshFuture = refreshFuture;
    refreshFuture.then<void>(
      (_) {
        if (identical(_refreshFuture, refreshFuture)) {
          _refreshFuture = null;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_refreshFuture, refreshFuture)) {
          _refreshFuture = null;
        }
      },
    );
    return (await refreshFuture)?.accessToken;
  }

  Future<_TokenPair?> _refreshTokens() async {
    final refreshToken = await SecureStorageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await SecureStorageService.clearTokens();
      AuthSessionEvents.emitSessionExpired();
      return null;
    }

    try {
      AppLogger.i('Attempting to refresh token');
      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: const <String, dynamic>{},
          extra: const <String, dynamic>{_skipRefreshExtra: true},
        ),
      );

      final data = refreshResponse.data;
      final responseData = data?['data'];
      final newAccessToken = responseData is Map ? responseData['token'] : null;
      final newRefreshToken = responseData is Map
          ? responseData['refresh_token']
          : null;

      if (refreshResponse.statusCode != 200 ||
          data?['status'] != 'success' ||
          newAccessToken is! String ||
          newAccessToken.isEmpty ||
          newRefreshToken is! String ||
          newRefreshToken.isEmpty) {
        AppLogger.e(
          'Refresh response did not match the authentication contract',
        );
        await SecureStorageService.clearTokens();
        AuthSessionEvents.emitSessionExpired();
        return null;
      }

      await SecureStorageService.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return _TokenPair(accessToken: newAccessToken);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      AppLogger.e('Token refresh failed', error.type);
      if (statusCode == 401 || statusCode == 403) {
        await SecureStorageService.clearTokens();
        AuthSessionEvents.emitSessionExpired();
      }
      return null;
    } catch (error) {
      AppLogger.e('Token refresh failed', error);
      return null;
    }
  }
}

class _TokenPair {
  final String accessToken;

  const _TokenPair({required this.accessToken});
}
