import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'auth_service.dart';
import '../main.dart';
import '../navigation/route_names.dart';
/// HTTP API client for the SaaradhiGo backend.
/// Handles base URL, headers, auth token injection, and response parsing.
class ApiClient {
  static const String baseUrl = 'http://localhost:8000/api/v1';

  /// Build headers with optional auth token
  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await StorageService.read(StorageService.keyAccessToken);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  static Future<ApiResponse> _performWithRetry(
    String endpoint,
    Future<http.Response> Function() requestAction,
    Future<ApiResponse> Function() retryAction,
  ) async {
    try {
      final response = await requestAction();

      // If 401 Unauthorized, and we are not calling an auth endpoint that shouldn't be retried
      if (response.statusCode == 401 && endpoint != '/auth/refresh/' && endpoint != '/auth/login/') {
        if (_isRefreshing) {
          // Wait for the ongoing refresh to finish
          final success = await _refreshCompleter!.future;
          if (success) {
            // Retry the original request
            return await retryAction();
          }
        } else {
          _isRefreshing = true;
          _refreshCompleter = Completer<bool>();

          final success = await AuthService.refreshToken();

          _isRefreshing = false;
          _refreshCompleter!.complete(success);

          if (success) {
            // Retry the original request
            return await retryAction();
          } else {
            // Refresh failed (e.g. refresh token expired)
            await AuthService.logout();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
          }
        }
      }

      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// POST request
  static Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    return _performWithRetry(
      endpoint,
      () async {
        final headers = await _headers(auth: auth);
        return await http
            .post(
              Uri.parse('$baseUrl$endpoint'),
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(const Duration(seconds: 30));
      },
      () => post(endpoint, body: body, auth: auth),
    );
  }

  /// GET request
  static Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool auth = true,
  }) async {
    return _performWithRetry(
      endpoint,
      () async {
        final headers = await _headers(auth: auth);
        var uri = Uri.parse('$baseUrl$endpoint');
        if (queryParams != null) {
          uri = uri.replace(queryParameters: queryParams);
        }
        return await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 30));
      },
      () => get(endpoint, queryParams: queryParams, auth: auth),
    );
  }

  /// PATCH request
  static Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _performWithRetry(
      endpoint,
      () async {
        final headers = await _headers(auth: auth);
        return await http
            .patch(
              Uri.parse('$baseUrl$endpoint'),
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(const Duration(seconds: 30));
      },
      () => patch(endpoint, body: body, auth: auth),
    );
  }

  /// DELETE request
  static Future<ApiResponse> delete(
    String endpoint, {
    bool auth = true,
  }) async {
    return _performWithRetry(
      endpoint,
      () async {
        final headers = await _headers(auth: auth);
        return await http
            .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
            .timeout(const Duration(seconds: 30));
      },
      () => delete(endpoint, auth: auth),
    );
  }

  /// PATCH request with Multipart (for file uploads)
  static Future<ApiResponse> patchMultipart(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    bool auth = true,
  }) async {
    return _performWithRetry(
      endpoint,
      () async {
        final headers = await _headers(auth: auth);
        // Remove Content-Type so http.MultipartRequest can set it with boundary
        headers.remove('Content-Type');

        final request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl$endpoint'));
        request.headers.addAll(headers);

        if (fields != null) {
          request.fields.addAll(fields);
        }

        if (files != null) {
          // Note: When recreating the request for a retry, the files list must contain fresh streams.
          // Since we might retry, we need to ensure files can be sent again.
          // The caller might need to handle this or pass file paths instead of streams.
          // For now, we assume the caller is passing files that can be read multiple times, 
          // or we recreate the MultipartFile instances if they fail.
          // In standard http.MultipartFile, reading from bytes can be done multiple times,
          // but reading from a stream cannot.
          request.files.addAll(files);
        }

        final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
        return await http.Response.fromStream(streamedResponse);
      },
      () => patchMultipart(endpoint, fields: fields, files: files, auth: auth),
    );
  }
}

/// Standardized API response wrapper
class ApiResponse {
  final bool success;
  final int statusCode;
  final Map<String, dynamic>? data;
  final String? message;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
  });

  factory ApiResponse.fromHttpResponse(http.Response response) {
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      parsed = null;
    }

    final isSuccess =
        response.statusCode >= 200 && response.statusCode < 300;
    final status = parsed?['status'];
    print(parsed);
    return ApiResponse(
      success: isSuccess && status == 'success',
      statusCode: response.statusCode,
      data: parsed?['data'] as Map<String, dynamic>?,
      message: isSuccess
          ? null
          : (parsed?['message'] ?? 'Request failed with status ${response.statusCode}'),
    );
  }
}
