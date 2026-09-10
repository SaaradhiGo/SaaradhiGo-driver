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

class DioClient {
  late final Dio _dio;

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

    _dio.interceptors.addAll([LoggingInterceptor(), AuthInterceptor(_dio)]);
  }

  Dio get dio => _dio;

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

      String? errorMessage;
      if (data != null &&
          data is Map<String, dynamic> &&
          data['message'] != null) {
        errorMessage = data['message'].toString();
      }

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
