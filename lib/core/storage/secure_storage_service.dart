import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/user_model.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserData = 'user_data';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  static Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _keyUserData, value: jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final str = await _storage.read(key: _keyUserData);
    if (str == null || str.isEmpty) return null;
    try {
      final json = jsonDecode(str);
      if (json is Map<String, dynamic>) {
        return UserModel.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserData);
  }
}
