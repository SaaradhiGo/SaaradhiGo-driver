/// Direct-to-S3 document upload, in the three steps the backend defines.
///
/// THE FLOW (see `base/uploads_views.py` and `base/s3.py`)
/// ------------------------------------------------------
///   1. `POST /uploads/presign/ {kind, content_type}`
///      -> `{kind, key, upload_url, expires_in}`
///   2. `PUT upload_url` with the bytes and **the exact Content-Type that was
///      signed**. A different type fails the signature, which is the single
///      easiest way to get this wrong.
///   3. Submit `key` to the normal API (`/driver/vehicles/add/`,
///      `/driver/driver/update/`). The server validates the key's prefix and
///      extension against the kind before it stores it.
///
/// Why direct-to-S3 and not multipart through Django: a 4 MB photo would
/// otherwise occupy a Daphne worker for the whole upload, on a driver's
/// 3G connection, while that worker is also serving dispatch.
///
/// WHAT THIS DELIBERATELY DOES NOT DO
/// ----------------------------------
/// It does not send the auth token to S3. The presigned URL *is* the
/// authorisation, and attaching a Bearer header to the PUT is both unnecessary
/// and a way to leak a token into a third party's access logs. The PUT
/// therefore uses a bare Dio, not the app's authenticated client.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// What a presign call came back with.
class PresignedUpload {
  const PresignedUpload({
    required this.kind,
    required this.key,
    required this.uploadUrl,
  });

  final String kind;

  /// The S3 object key. **This** is what gets submitted to the API, never the
  /// upload URL (which carries a signature and an expiry).
  final String key;
  final String uploadUrl;
}

class UploadClient {
  UploadClient(this._api, {Dio? putClient})
      : _put = putClient ??
            Dio(BaseOptions(
              // A document photo on a weak connection. Longer than the app's
              // normal API timeouts, which are tuned for small JSON.
              sendTimeout: const Duration(seconds: 90),
              receiveTimeout: const Duration(seconds: 30),
            ));

  final ApiClient _api;
  final Dio _put;

  static const String _presignPath = '/uploads/presign/';

  /// Content types the backend's document kinds accept.
  ///
  /// Derived from the file extension rather than sniffed: the server checks the
  /// extension of the key it generated, so these two have to agree and a
  /// mismatch is a rejected upload rather than a corrupt one.
  static String contentTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      // The server does not accept HEIC. Saying so here produces a clear
      // message instead of a signature failure the driver cannot act on.
      throw const ApiException(
        message: 'That photo format is not supported. Please choose a JPEG '
            'or PNG, or retake the photo.',
      );
    }
    return 'image/jpeg';
  }

  /// Step 1.
  Future<PresignedUpload> presign({
    required String kind,
    required String contentType,
  }) async {
    final data = await _api.post(
      _presignPath,
      body: {'kind': kind, 'content_type': contentType},
    );

    final key = data['key'] as String?;
    final url = data['upload_url'] as String?;
    if (key == null || url == null) {
      throw const ApiException(
        message: 'Upload could not be started. Please try again.',
      );
    }
    return PresignedUpload(
      kind: data['kind'] as String? ?? kind,
      key: key,
      uploadUrl: url,
    );
  }

  /// Steps 1-3's middle: PUT the bytes to S3.
  ///
  /// [onProgress] is reported 0..1 so a driver on a slow connection sees
  /// something move rather than a frozen screen.
  Future<void> putBytes({
    required PresignedUpload target,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      await _put.put<void>(
        target.uploadUrl,
        data: Stream<List<int>>.fromIterable([bytes]),
        options: Options(
          headers: {
            // Exactly what was signed. Dio would otherwise send
            // application/octet-stream and S3 would reject the signature.
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) onProgress(sent / total);
        },
      );
    } on DioException catch (e) {
      // S3 replies with an XML error body that means nothing to a driver.
      throw ApiException(
        message: 'Upload failed. Check your connection and try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// The whole thing: presign, upload, return the key to submit.
  Future<String> uploadFile({
    required String kind,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final contentType = contentTypeFor(file.path);
    final bytes = await file.readAsBytes();

    // 10 MB. The server caps document size too; failing here saves a driver
    // uploading a 40 MB photo over mobile data before being told no.
    const int maxBytes = 10 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      throw const ApiException(
        message: 'That file is too large. Please use a photo under 10 MB.',
      );
    }

    final target = await presign(kind: kind, contentType: contentType);
    await putBytes(
      target: target,
      bytes: bytes,
      contentType: contentType,
      onProgress: onProgress,
    );
    return target.key;
  }
}
