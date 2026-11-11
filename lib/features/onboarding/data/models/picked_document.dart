import 'dart:io';
import 'dart:typed_data';

/// A file picked on a screen, platform-agnostically.
///
/// - Native: callers pass [path] (optionally pre-loaded [bytes]).
/// - Web: browsers do not expose paths, so callers pass [bytes] or a
///   [loadBytes] closure (e.g. `XFile.readAsBytes`).
class PickedDocument {
  const PickedDocument({
    this.path,
    this.name,
    this.bytes,
    Future<Uint8List> Function()? loadBytes,
  }) : _loadBytes = loadBytes;

  /// Absolute local path (native platforms only, `null` on web).
  final String? path;

  /// Original file name including extension, used for MIME detection.
  final String? name;

  /// Pre-loaded bytes (web picks, or already-compressed images).
  final Uint8List? bytes;

  final Future<Uint8List> Function()? _loadBytes;

  bool get isAvailable =>
      (path != null && path!.isNotEmpty) ||
      (bytes != null && bytes!.isNotEmpty) ||
      _loadBytes != null;

  Future<Uint8List> resolveBytes() async {
    final preloaded = bytes;
    if (preloaded != null && preloaded.isNotEmpty) {
      return preloaded;
    }
    final loader = _loadBytes;
    if (loader != null) {
      return loader();
    }
    final localPath = path;
    if (localPath != null && localPath.isNotEmpty) {
      return File(localPath).readAsBytes();
    }
    throw StateError('PickedDocument has no readable content.');
  }
}
