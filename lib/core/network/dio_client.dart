import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';
import '../errors/failures.dart';
import '../utils/app_logger.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// The access token a WebSocket should connect with.
///
/// Sockets used to read storage directly, which meant connecting with whatever
/// was last written there -- including an access token that had already
/// expired. This goes through the same refresh the REST client uses, so the
/// three driver sockets and Dio can never disagree about who is signed in.
final socketAccessTokenProvider = Provider<Future<String?> Function()>((ref) {
  final client = ref.watch(dioClientProvider);
  return client.freshAccessToken;
});

class DioClient {
  late final Dio _dio;
  late final AuthInterceptor _auth;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _auth = AuthInterceptor(_dio);
    _dio.interceptors.addAll([LoggingInterceptor(), _auth]);
  }

  Dio get dio => _dio;

  /// An access token that has not already expired, refreshing it if needed.
  /// Used by the WebSocket URL builders, which cannot rely on a 401.
  Future<String?> freshAccessToken() => _auth.ensureFreshAccessToken();

  /// Helper method to execute requests and standardise error handling
  Future<dynamic> request(Future<Response> Function() requestFunction) async {
    try {
      final response = await requestFunction();
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      AppLogger.e('Unexpected error', e);
      throw const UnknownFailure();
    }
  }

  /// The server's own explanation of a failure.
  ///
  /// This read only `data['message']`, which this API never sends. Every
  /// error envelope is `{"status": "error", "error": {"code": ..., "message":
  /// ...}}`, so a rejected login showed the hardcoded "Authentication failed"
  /// instead of "Invalid email or password." -- the one message that tells a
  /// driver what to do next. `detail` is DRF's own default, which a view that
  /// raises before the envelope wrapper can still produce.
  String? _messageFrom(dynamic data) {
    if (data is! Map) return null;

    final error = data['error'];
    if (error is Map && error['message'] != null) {
      return error['message'].toString();
    }
    if (data['message'] != null) return data['message'].toString();
    if (data['detail'] != null) return data['detail'].toString();
    return null;
  }

  void _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const NetworkFailure();
    }

    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      final errorMessage = _messageFrom(data);

      if (statusCode == 401 || statusCode == 403) {
        throw AuthFailure(errorMessage ?? 'Authentication failed');
      } else if (statusCode == 400 || statusCode == 422) {
        throw ValidationFailure(errorMessage ?? 'Validation failed');
      } else if (statusCode != null && statusCode >= 500) {
        throw ServerFailure(errorMessage ?? 'Server error occurred');
      } else {
        throw UnknownFailure(errorMessage ?? 'An unknown error occurred');
      }
    } else {
      throw const UnknownFailure('Network request failed');
    }
  }
}
