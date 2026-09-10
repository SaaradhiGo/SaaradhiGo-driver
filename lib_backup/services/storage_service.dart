import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure local storage wrapper for persisting sensitive data
/// like auth tokens, refresh tokens, and user info.
class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyPhoneNumber = 'phone_number';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserRole = 'user_role';
  static const String keyUserProfile = 'user_profile';

  /// Write a value to secure storage
  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value from secure storage
  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete a specific key from secure storage
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all stored values (used on logout)
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists in storage
  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
}
