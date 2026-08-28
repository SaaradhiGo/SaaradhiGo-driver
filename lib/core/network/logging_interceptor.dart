import 'package:dio/dio.dart';

import '../utils/app_logger.dart';

class LoggingInterceptor extends Interceptor {
  static const _sensitiveKeys = {
    'authorization',
    'access_token',
    'refresh_token',
    'token',
    'otp',
    'device_token',
    'password',
    // Presigned S3 URLs are secrets: anyone holding one can upload/overwrite
    // the object until it expires.
    'upload_url',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.i('=> ${options.method} ${options.uri}');
    AppLogger.d('Headers: ${_redactMap(options.headers)}');
    if (_isSafeToLog(options.data)) {
      AppLogger.d('Body: ${_redactValue(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.i('<= ${response.statusCode} ${response.requestOptions.uri}');
    if (_isSafeToLog(response.data)) {
      AppLogger.d('Response: ${_redactValue(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '<= Error ${err.response?.statusCode} ${err.requestOptions.uri}',
      err.message,
      err.stackTrace,
    );
    if (_isSafeToLog(err.response?.data)) {
      AppLogger.e('Error Data: ${_redactValue(err.response?.data)}');
    }
    handler.next(err);
  }

  bool _isSafeToLog(Object? value) {
    return value is! FormData && value is! List<int> && value is! Stream;
  }

  Object? _redactValue(Object? value) {
    if (value is Map) {
      return _redactMap(value);
    }
    if (value is Iterable) {
      return value.map(_redactValue).toList(growable: false);
    }
    return value;
  }

  Map<String, Object?> _redactMap(Map value) {
    return value.map(
      (key, item) => MapEntry(
        key.toString(),
        _sensitiveKeys.contains(key.toString().toLowerCase())
            ? '[REDACTED]'
            : _redactValue(item),
      ),
    );
  }
}
