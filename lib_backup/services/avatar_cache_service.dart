import 'dart:convert';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class AvatarCacheService {
  static const String _avatarStorageKey = 'cached_driver_avatar';

  /// Get the local avatar bytes if they exist, otherwise return null
  static Future<Uint8List?> getLocalAvatarBytes() async {
    try {
      final base64String = await StorageService.read(_avatarStorageKey);
      if (base64String != null && base64String.isNotEmpty) {
        return base64Decode(base64String);
      }
    } catch (e) {
      print('Error getting local avatar: $e');
    }
    return null;
  }

  /// Download the avatar from S3 and save it locally
  static Future<Uint8List?> downloadAndSaveAvatar(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final base64String = base64Encode(bytes);
        await StorageService.write(_avatarStorageKey, base64String);
        return bytes;
      } else {
        print('Failed to download avatar: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading avatar: $e');
    }
    return null;
  }

  /// Update the local avatar directly from an XFile (after picking a new image)
  static Future<Uint8List?> updateLocalAvatar(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      await StorageService.write(_avatarStorageKey, base64String);
      return bytes;
    } catch (e) {
      print('Error updating local avatar: $e');
    }
    return null;
  }

  /// Clear the local avatar file (e.g., on logout)
  static Future<void> clearAvatar() async {
    try {
      if (await StorageService.containsKey(_avatarStorageKey)) {
        await StorageService.delete(_avatarStorageKey);
      }
    } catch (e) {
      print('Error clearing local avatar: $e');
    }
  }
}
