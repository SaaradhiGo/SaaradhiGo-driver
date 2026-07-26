import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access + refresh tokens, held in the Keychain (iOS) /
/// EncryptedSharedPreferences (Android).
///
/// Never plain SharedPreferences: on a rooted or backed-up device that file is
/// readable, and a driver's token grants access to their earnings, their payout
/// details and their live location.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _kAccess = 'driver_access_token';
  static const _kRefresh = 'driver_refresh_token';

  Future<String?> readAccess() => _storage.read(key: _kAccess);
  Future<String?> readRefresh() => _storage.read(key: _kRefresh);

  Future<void> write({required String access, String? refresh}) async {
    await _storage.write(key: _kAccess, value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: _kRefresh, value: refresh);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  Future<bool> hasSession() async {
    final token = await readAccess();
    return token != null && token.isNotEmpty;
  }
}
