import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../network/api_endpoints.dart';
import 'upload_exceptions.dart';
import 'upload_kind.dart';

/// Uploads files straight to S3 using backend-issued presigned URLs:
///
/// 1. `POST /uploads/presign/` (authenticated) → `{key, upload_url, headers}`.
/// 2. `PUT <upload_url>` with the raw bytes — no auth/JWT/x-amz-* headers, the
///    `Content-Type` must be byte-for-byte the one returned by the presign
///    response or S3 answers 403.
/// 3. The caller submits the resulting [S3UploadResult.key] to the normal JSON
///    endpoint (`/driver/vehicles/add/`, `/auth/update/`, ...).
///
/// Signed URLs are secrets: they are never logged by this service.
class PresignedUploadService {
  PresignedUploadService({
    required Dio dio,
    DateTime Function()? now,
    @visibleForTesting Dio? s3Client,
  }) : _dio = dio,
       _now = now ?? DateTime.now {
    // Dedicated client for the S3 PUT: absolute URLs, no baseUrl, and
    // deliberately NO interceptors so neither an Authorization header nor the
    // signed URL can ever reach the logs.
    _s3Dio =
        s3Client ??
        Dio(
          BaseOptions(
            connectTimeout: _connectTimeout,
            sendTimeout: _putTimeout,
            receiveTimeout: _putTimeout,
          ),
        );
  }

  final Dio _dio;
  final DateTime Function() _now;
  late final Dio _s3Dio;

  /// Hard timeout for a single S3 PUT attempt.
  static const _putTimeout = Duration(seconds: 120);
  static const _connectTimeout = Duration(seconds: 30);

  /// Upper bound of the presigned URL risk window. Backend `expires_in` is
  /// 900 s; anything past this requires a re-presign (ask the user to retry).
  static const _maxUploadDuration = Duration(minutes: 10);

  /// Safety margin subtracted from `expires_in` to absorb clock drift between
  /// the device and AWS.
  static const _presignExpiryMargin = Duration(seconds: 30);

  static const _defaultExpiresIn = 900;

  Future<S3UploadResult> upload({
    required UploadKind kind,
    required Uint8List bytes,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final validationError = UploadValidator.validate(
      kind: kind,
      mimeType: mimeType,
      byteLength: bytes.length,
    );
    if (validationError != null) {
      throw UploadValidationException(validationError);
    }

    var grant = await _presign(kind: kind, mimeType: mimeType);

    var retriedAfterForbidden = false;
    while (true) {
      _ensureWithinRiskWindow(grant);
      try {
        await _putBytes(
          grant: grant,
          bytes: bytes,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
        return S3UploadResult(key: grant.key);
      } on DioException catch (e) {
        if (cancelToken?.isCancelled ?? false) {
          throw const UploadCancelledException();
        }
        if (e.response?.statusCode == 403 && !retriedAfterForbidden) {
          // Most likely clock drift between the device and S3 invalidated the
          // signature. Re-presign exactly once and retry the PUT.
          retriedAfterForbidden = true;
          grant = await _presign(kind: kind, mimeType: mimeType);
          continue;
        }
        throw _mapPutFailure(e);
      }
    }
  }

  Future<_PresignGrant> _presign({
    required UploadKind kind,
    required String mimeType,
  }) async {
    final dynamic response = await _requestPresign(
      body: {'kind': kind.wireName, 'content_type': mimeType},
    );

    final Map<String, dynamic> envelope = response is Map<String, dynamic>
        ? response
        : const {};
    final payload = envelope['data'];
    if (envelope['status'] != 'success' || payload is! Map<String, dynamic>) {
      throw const UploadServerException(
        'The upload could not be prepared. Please try again.',
      );
    }

    final key = payload['key'];
    final uploadUrl = payload['upload_url'];
    final method = payload['method'];
    if (key is! String ||
        key.isEmpty ||
        uploadUrl is! String ||
        uploadUrl.isEmpty) {
      throw const UploadServerException(
        'The upload could not be prepared. Please try again.',
      );
    }
    if (method is String && method.toUpperCase() != 'PUT') {
      throw const UploadServerException(
        'The upload could not be prepared. Please try again.',
      );
    }

    final headers = payload['headers'];
    final contentType = headers is Map<String, dynamic>
        ? headers['Content-Type']
        : null;

    return _PresignGrant(
      key: key,
      uploadUrl: uploadUrl,
      contentType: contentType is String && contentType.isNotEmpty
          ? contentType
          : mimeType,
      expiresIn: payload['expires_in'] is int
          ? payload['expires_in'] as int
          : _defaultExpiresIn,
      presignedAt: _now(),
    );
  }

  Future<dynamic> _requestPresign({required Map<String, dynamic> body}) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.presignUpload,
        data: body,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapPresignFailure(e);
    }
  }

  Future<void> _putBytes({
    required _PresignGrant grant,
    required Uint8List bytes,
    required void Function(int sent, int total)? onProgress,
    required CancelToken? cancelToken,
  }) async {
    // Raw bytes only — never multipart/form-data. The Content-Type must match
    // the signed value exactly; adding Authorization or x-amz-* headers here
    // invalidates the SigV4 signature.
    await _s3Dio.put<void>(
      grant.uploadUrl,
      data: bytes,
      options: Options(
        headers: {'Content-Type': grant.contentType},
        contentType: grant.contentType,
        sendTimeout: _putTimeout,
        receiveTimeout: _putTimeout,
      ),
      onSendProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  /// Effective risk window for a grant: `expires_in` minus the drift margin,
  /// capped at [_maxUploadDuration].
  @visibleForTesting
  static Duration effectiveRiskWindow(int expiresInSeconds) {
    final expiresIn = Duration(seconds: expiresInSeconds);
    return expiresIn < _maxUploadDuration + _presignExpiryMargin
        ? expiresIn - _presignExpiryMargin
        : _maxUploadDuration;
  }

  void _ensureWithinRiskWindow(_PresignGrant grant) {
    final age = _now().difference(grant.presignedAt);
    if (age > effectiveRiskWindow(grant.expiresIn)) {
      throw const UploadExpiredException();
    }
  }

  Never _mapPresignFailure(DioException e) {
    final serverMessage = extractServerErrorMessage(e.response?.data);
    switch (e.response?.statusCode) {
      case 400:
        throw UploadValidationException(
          serverMessage ?? 'This file type cannot be uploaded.',
        );
      case 401:
        throw const UploadAuthException();
      case 403:
        throw serverMessage == null
            ? const UploadForbiddenException()
            : UploadForbiddenException(serverMessage);
      default:
        if (_isNetworkError(e)) {
          throw const UploadNetworkException();
        }
        throw serverMessage == null
            ? const UploadServerException(
                'The upload could not be prepared. Please try again.',
              )
            : UploadServerException(serverMessage);
    }
  }

  Never _mapPutFailure(DioException e) {
    if (_isNetworkError(e)) {
      throw const UploadNetworkException();
    }
    final status = e.response?.statusCode;
    if (status == 403) {
      // Exhausted the single re-presign retry: persistent signature rejection.
      throw const UploadForbiddenException(
        'The file upload was rejected. Please try again.',
      );
    }
    if (status != null && status >= 500) {
      throw const UploadServerException('Upload failed on the server.');
    }
    throw UploadServerException('Upload failed (HTTP ${status ?? 'error'}).');
  }

  bool _isNetworkError(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError ||
      e.error != null && e.response == null;

  /// Extracts a user-facing message from both error envelopes used by the
  /// backend: the new `{status: "error", error: {code, message}}` shape and
  /// the legacy top-level `{message: ...}` shape.
  static String? extractServerErrorMessage(dynamic body) {
    if (body is! Map) {
      return null;
    }
    final error = body['error'];
    if (error is Map) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      final details = error['details'];
      if (details is Map) {
        final issue = details['issue'];
        if (issue is String && issue.isNotEmpty) {
          return issue;
        }
      }
    }
    final legacy = body['message'];
    if (legacy is String && legacy.isNotEmpty) {
      return legacy;
    }
    return null;
  }
}

class _PresignGrant {
  const _PresignGrant({
    required this.key,
    required this.uploadUrl,
    required this.contentType,
    required this.expiresIn,
    required this.presignedAt,
  });

  final String key;
  final String uploadUrl;
  final String contentType;
  final int expiresIn;
  final DateTime presignedAt;
}
