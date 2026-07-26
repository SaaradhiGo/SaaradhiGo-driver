import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

/// Called when the refresh token is dead and the driver has to sign in again.
typedef SessionExpiredCallback = void Function();

/// The single HTTP entry point for the app.
///
/// Responsibilities kept deliberately here rather than in every repository:
///   * attach the bearer token
///   * refresh once on 401 and replay the original request
///   * collapse concurrent refreshes into one in-flight call
///   * unwrap the backend's `{status, data}` envelope
///   * translate everything into [ApiException]
///
/// Access tokens live 15 minutes, so a driver on a 10-hour shift will hit
/// expiry repeatedly. Refresh has to be invisible: a driver must never be
/// bounced to a login screen while a rider is in their car.
class ApiClient {
  ApiClient(
    this._tokenStore, {
    Dio? dio,
    this.onSessionExpired,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = AppConfig.connectTimeout
      ..receiveTimeout = AppConfig.receiveTimeout
      ..sendTimeout = AppConfig.receiveTimeout
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final Dio _dio;
  final TokenStore _tokenStore;
  final SessionExpiredCallback? onSessionExpired;

  /// Shared across callers so a burst of 401s (home + earnings + profile all
  /// refreshing at once) triggers exactly one refresh round-trip.
  Future<String?>? _inflightRefresh;

  Dio get raw => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      final token = await _tokenStore.readAccess();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthRoute = err.requestOptions.extra['skipAuth'] == true;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (err.response?.statusCode != 401 || isAuthRoute || alreadyRetried) {
      handler.next(err);
      return;
    }

    final newToken = await _refreshToken();
    if (newToken == null) {
      onSessionExpired?.call();
      handler.next(err);
      return;
    }

    try {
      final options = err.requestOptions;
      options.extra['retried'] = true;
      options.headers['Authorization'] = 'Bearer $newToken';
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refreshToken() {
    final inflight = _inflightRefresh;
    if (inflight != null) return inflight;

    final future = _doRefresh().whenComplete(() => _inflightRefresh = null);
    _inflightRefresh = future;
    return future;
  }

  Future<String?> _doRefresh() async {
    final refresh = await _tokenStore.readRefresh();
    if (refresh == null || refresh.isEmpty) return null;

    try {
      // Same Dio, so the refresh shares the app's base URL, timeouts and
      // (in tests) the injected adapter. `skipAuth` stops the 401 interceptor
      // recursing into itself if the refresh is the thing being rejected.
      final response = await _dio.post<dynamic>(
        ApiEndpoints.refresh,
        data: {'refresh_token': refresh},
        options: Options(extra: {'skipAuth': true, 'retried': true}),
      );

      final body = unwrap(response.data);
      final access = body?['access'] as String?;
      final newRefresh = body?['refresh'] as String?;
      if (access == null || access.isEmpty) return null;

      await _tokenStore.write(access: access, refresh: newRefresh);
      return access;
    } on DioException {
      // Refresh tokens rotate and are single-use server-side, so a failure
      // here means this device's token is genuinely spent.
      await _tokenStore.clear();
      return null;
    }
  }

  /// Unwrap `{status: "success", data: ..., meta: ...}`.
  ///
  /// Some endpoints (DRF paginated lists) answer without the envelope, so a
  /// body with no `data` key is passed through as-is rather than nulled out.
  static Map<String, dynamic>? unwrap(dynamic body) {
    if (body is! Map) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null) return body.cast<String, dynamic>();
    // `data` was a list or scalar — hand the caller the envelope so it can
    // pick the field it wants.
    return body.cast<String, dynamic>();
  }

  static List<dynamic> unwrapList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final data = body['data'];
      if (data is List) return data;
      if (data is Map && data['results'] is List) {
        return data['results'] as List<dynamic>;
      }
      if (body['results'] is List) return body['results'] as List<dynamic>;
    }
    return const [];
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      return unwrap(response.data) ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      return unwrapList(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
      return unwrap(response.data) ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    try {
      final response = await _dio.patch<dynamic>(path, data: body);
      return unwrap(response.data) ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    try {
      final response = await _dio.put<dynamic>(path, data: body);
      return unwrap(response.data) ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
