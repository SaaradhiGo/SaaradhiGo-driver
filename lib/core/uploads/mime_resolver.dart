import 'dart:typed_data';

import 'package:mime/mime.dart';

/// Resolves the MIME type of a picked file.
///
/// A strict extension allow-list is checked first (only types the backend can
/// presign for), then the `mime` package lookup runs as a fallback for less
/// common but still valid extensions.
class MimeTypeResolver {
  const MimeTypeResolver();

  static const Map<String, String> _extensionToMime = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'pdf': 'application/pdf',
  };

  /// Returns the resolved MIME type, or `null` when it cannot be determined
  /// (the caller should reject the file client-side).
  String? resolve({String? fileName, Uint8List? bytes}) {
    final extension = _extensionOf(fileName);
    if (extension != null) {
      final known = _extensionToMime[extension];
      if (known != null) {
        return known;
      }
      // Unknown extension: let the mime package take a broader guess before
      // giving up.
      final guessed = fileName == null ? null : lookupMimeType(fileName);
      if (guessed != null) {
        return guessed;
      }
      return null;
    }

    if (fileName != null && fileName.trim().isNotEmpty) {
      return lookupMimeType(fileName, headerBytes: bytes);
    }
    if (bytes != null && bytes.isNotEmpty) {
      return lookupMimeType('', headerBytes: bytes);
    }
    return null;
  }

  String? _extensionOf(String? fileName) {
    if (fileName == null) {
      return null;
    }
    final trimmed = fileName.trim();
    if (trimmed.isEmpty || !trimmed.contains('.')) {
      return null;
    }
    return trimmed.split('.').last.toLowerCase();
  }
}
