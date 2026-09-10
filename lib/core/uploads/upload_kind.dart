/// Progress callback for file uploads: (bytesSent, bytesTotal).
typedef UploadProgressCallback = void Function(int sent, int total);

/// Kinds of files the backend can presign for direct-to-S3 uploads.
///
/// The wire names, allowed MIME types and size limits mirror the backend
/// contract for `POST /uploads/presign/` exactly. Any change on the backend
/// side must be reflected here.
enum UploadKind {
  avatar('avatar'),
  vehiclePic('vehicle_pic'),
  licenseDoc('license_doc'),
  // Licence back side. [CONFIRMED] API_Documentation_V2 §3.6 lists this
  // presign kind (5 MB, images + PDF); §3.2 documents the matching optional
  // `license_doc_back` field on PATCH /driver/driver/update/ (not required
  // for KYC).
  licenseDocBack('license_doc_back'),
  rcDoc('rc_doc');

  const UploadKind(this.wireName);

  /// Value sent in the `kind` field of the presign request body.
  final String wireName;

  /// Server-side limit: uploads larger than this are rejected when the key is
  /// submitted. We validate client-side to fail fast.
  static const int maxBytes = 5 * 1024 * 1024;

  static const Set<String> _imageMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  };

  static const Set<String> _documentExtraMimeTypes = {'application/pdf'};

  Set<String> get allowedMimeTypes => switch (this) {
    UploadKind.avatar || UploadKind.vehiclePic => _imageMimeTypes,
    UploadKind.licenseDoc ||
    UploadKind.licenseDocBack ||
    UploadKind.rcDoc => {..._imageMimeTypes, ..._documentExtraMimeTypes},
  };

  bool allowsMimeType(String mimeType) =>
      allowedMimeTypes.contains(mimeType.toLowerCase());

  String get friendlyTypeHint => switch (this) {
    UploadKind.avatar ||
    UploadKind.vehiclePic => 'JPG, PNG, WebP or GIF images',
    UploadKind.licenseDoc ||
    UploadKind.licenseDocBack ||
    UploadKind.rcDoc => 'JPG, PNG, WebP or GIF images, or PDF documents',
  };
}

/// Pure client-side validation executed before any network call so that
/// invalid picks fail fast with friendly messages instead of a server 400.
abstract final class UploadValidator {
  /// Returns `null` when the upload payload is acceptable, otherwise a
  /// user-facing error message.
  static String? validate({
    required UploadKind kind,
    required String mimeType,
    required int byteLength,
  }) {
    if (byteLength <= 0) {
      return 'The selected file is empty. Please choose a valid file.';
    }
    if (byteLength > UploadKind.maxBytes) {
      return 'File is too large. The maximum allowed size is 5 MB.';
    }
    if (!kind.allowsMimeType(mimeType)) {
      return 'Unsupported file type. Please use ${kind.friendlyTypeHint}.';
    }
    return null;
  }
}
