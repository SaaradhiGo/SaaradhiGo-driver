import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

/// HTTP API client for the SaaradhiGo backend.
/// Handles base URL, headers, auth token injection, and response parsing.
class ApiClient {
  static const String baseUrl = 'https://dev.api.saaradhigo.in/api/v1';

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

  /// POST request
  static Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    try {
      final headers = await _headers(auth: auth);
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// GET request
  static Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool auth = true,
  }) async {
    try {
      final headers = await _headers(auth: auth);
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// PATCH request
  static Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final headers = await _headers(auth: auth);
      final response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// DELETE request
  static Future<ApiResponse> delete(
    String endpoint, {
    bool auth = true,
  }) async {
    try {
      final headers = await _headers(auth: auth);
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 30));

      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
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
