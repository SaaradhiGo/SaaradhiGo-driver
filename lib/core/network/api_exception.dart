import 'package:dio/dio.dart';

/// A failure the UI can render without knowing anything about Dio.
///
/// The backend wraps every error as
/// `{status: "error", error: {code, message, details}}`, so we surface the
/// server's own message where there is one. Those strings are written for
/// drivers ("You have reached the 12-hour daily limit, or are in a cooldown
/// after recent cancellations") and are far better than anything this layer
/// could invent.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.isNetwork = false,
  });

  final String message;
  final String? code;
  final int? statusCode;

  /// True when the request never reached the server. The UI offers a retry for
  /// these instead of treating them as a permanent failure.
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isRateLimited => statusCode == 429;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'The network is slow right now. Try again.',
          code: 'TIMEOUT',
          isNetwork: true,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          message: 'No connection. Check your mobile data and try again.',
          code: 'OFFLINE',
          isNetwork: true,
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Cancelled', code: 'CANCELLED');
      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Could not verify a secure connection.',
          code: 'BAD_CERTIFICATE',
        );
      case DioExceptionType.badResponse:
        return ApiException._fromResponse(e.response);
      // Dio 5.9 added transformTimeout; treat it as any other slow path.
      default:
        return const ApiException(
          message: 'The network is slow right now. Try again.',
          code: 'TIMEOUT',
          isNetwork: true,
        );
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final data = response?.data;

    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        final message = error['message'];
        return ApiException(
          message: message is String && message.trim().isNotEmpty
              ? message
              : _defaultFor(status),
          code: error['code'] as String?,
          statusCode: status,
        );
      }
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return ApiException(message: detail, statusCode: status);
      }
    }
    return ApiException(message: _defaultFor(status), statusCode: status);
  }

  static String _defaultFor(int? status) {
    switch (status) {
      case 401:
        return 'Your session expired. Sign in again.';
      case 403:
        return 'You do not have access to that.';
      case 404:
        return 'Not found.';
      case 409:
        return 'That has already been done.';
      case 429:
        return 'Too many attempts. Wait a moment and try again.';
      case 502:
      case 503:
        return 'The service is temporarily unavailable. Try again shortly.';
      default:
        return 'Something went wrong. Try again.';
    }
  }

  @override
  String toString() => 'ApiException($code/$statusCode): $message';
}
