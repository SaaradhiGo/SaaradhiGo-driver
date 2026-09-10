/// Typed failures raised by [PresignedUploadService].
///
/// Repositories translate these into the shared [Failure] hierarchy so screens
/// can keep surfacing errors through the existing snackbar flow.
sealed class UploadException implements Exception {
  const UploadException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Client-side rejection (size, MIME type, empty file) before any network call,
/// or a server-side `INVALID_*` presign rejection.
final class UploadValidationException extends UploadException {
  const UploadValidationException(super.message);
}

/// Presign returned 401 even after the auth interceptor refreshed the token.
final class UploadAuthException extends UploadException {
  const UploadAuthException([
    super.message = 'Your session has expired. Please login again.',
  ]);
}

/// Presign or S3 rejected the request with 403 (e.g. rider uploading a driver
/// document, `DRIVER_REQUIRED`).
final class UploadForbiddenException extends UploadException {
  const UploadForbiddenException([
    super.message = 'You are not allowed to upload this file.',
  ]);
}

/// Connection failure or timeout during presign or the S3 PUT.
final class UploadNetworkException extends UploadException {
  const UploadNetworkException([
    super.message =
        'Upload failed due to a network problem. Please check your '
        'connection and try again.',
  ]);
}

/// The presigned URL risk window (`expires_in`, capped at 10 minutes) elapsed
/// before the upload completed. Retrying re-presigns a fresh URL.
final class UploadExpiredException extends UploadException {
  const UploadExpiredException([
    super.message =
        'The upload took too long and its secure link expired. '
        'Please try again.',
  ]);
}

/// Non-retryable HTTP failure from S3 (e.g. 5xx).
final class UploadServerException extends UploadException {
  const UploadServerException([super.message = 'Upload failed on the server.']);
}

/// The user (or screen disposal) cancelled an in-flight upload.
final class UploadCancelledException extends UploadException {
  const UploadCancelledException([super.message = 'Upload cancelled.']);
}

/// Successful outcome of a direct-to-S3 upload: the object key that must be
/// submitted to the regular JSON endpoints.
class S3UploadResult {
  const S3UploadResult({required this.key});

  /// Object key as returned by the presign response (e.g. `rc_docs/<hex>.png`).
  final String key;
}
