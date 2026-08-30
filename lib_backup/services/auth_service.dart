import 'dart:convert';
import 'api_client.dart';
import 'storage_service.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'avatar_cache_service.dart';

/// Authentication service for the SaaradhiGo Driver App.
/// Integrates with the real backend API at dev.api.saaradhigo.in.
///
/// Endpoints used:
///   POST /auth/otp/     — Request OTP
///   POST /auth/login/   — Verify OTP & get JWT tokens
///   POST /auth/refresh/ — Refresh access token
///   GET  /auth/profile/ — Get user profile
class AuthService {
  /// Send OTP to the given phone number.
  /// Phone must be E.164 format (e.g., +919876543210).
  /// Returns the API response with task_id and expires_in on success.
  static Future<ApiResponse> sendOtp(String phoneNumber) async {
    return await ApiClient.post(
      '/auth/otp/',
      body: {'phone_number': phoneNumber, 'role': 'driver'},
    );
  }

  /// Verify OTP and obtain JWT tokens.
  /// On success, persists access_token, refresh_token, and user data
  /// to secure storage.
  static Future<ApiResponse> verifyOtp(String phoneNumber, String otp) async {
    final response = await ApiClient.post(
      '/auth/login/',
      body: {'phone_number': phoneNumber, 'otp': otp},
    );

    if (response.success && response.data != null) {
      // Persist tokens
      final token = response.data!['token'] as String?;
      final refreshToken = response.data!['refresh_token'] as String?;

      if (token != null) {
        await StorageService.write(StorageService.keyAccessToken, token);
      }
      if (refreshToken != null) {
        await StorageService.write(
          StorageService.keyRefreshToken,
          refreshToken,
        );
      }

      // Persist user info
      final user = response.data!['user'] as Map<String, dynamic>?;
      if (user != null) {
        await StorageService.write(
          StorageService.keyUserProfile,
          jsonEncode(user),
        );

        final userId = user['id'];
        if (userId != null) {
          await StorageService.write(
            StorageService.keyUserId,
            userId.toString(),
          );
        }
        final fullName = user['full_name'] as String?;
        if (fullName != null) {
          await StorageService.write(StorageService.keyUserName, fullName);
        }
        final phone = user['phone_number'] as String?;
        if (phone != null) {
          await StorageService.write(StorageService.keyPhoneNumber, phone);
        }
        final role = user['role'] as String?;
        if (role != null) {
          await StorageService.write(StorageService.keyUserRole, role);
        }
      }
    }

    return response;
  }

  /// Refresh the access token using the stored refresh token.
  /// Updates secure storage with new tokens on success.
  static Future<bool> refreshToken() async {
    final refreshToken = await StorageService.read(
      StorageService.keyRefreshToken,
    );
    if (refreshToken == null) return false;

    final response = await ApiClient.post(
      '/auth/refresh/',
      body: {'refresh_token': refreshToken},
    );

    if (response.success && response.data != null) {
      final newToken = response.data!['token'] as String?;
      final newRefreshToken = response.data!['refresh_token'] as String?;

      if (newToken != null) {
        await StorageService.write(StorageService.keyAccessToken, newToken);
      }
      if (newRefreshToken != null) {
        await StorageService.write(
          StorageService.keyRefreshToken,
          newRefreshToken,
        );
      }
      return true;
    }
    return false;
  }

  /// Check if the user is currently authenticated.
  /// Verifies that a valid access token exists in secure storage.
  static Future<bool> isAuthenticated() async {
    final token = await StorageService.read(StorageService.keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  /// Get the current access token.
  static Future<String?> getToken() async {
    return await StorageService.read(StorageService.keyAccessToken);
  }

  /// Get the stored user profile data.
  static Future<Map<String, String?>> getStoredUser() async {
    return {
      'id': await StorageService.read(StorageService.keyUserId),
      'name': await StorageService.read(StorageService.keyUserName),
      'phone': await StorageService.read(StorageService.keyPhoneNumber),
      'role': await StorageService.read(StorageService.keyUserRole),
    };
  }

  /// Get the stored user profile data (complete JSON).
  static Future<Map<String, dynamic>?> getStoredUserProfile() async {
    final data = await StorageService.read(StorageService.keyUserProfile);
    if (data != null) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  /// Fetch the user profile from the API.
  static Future<ApiResponse> fetchProfile() async {
    final response = await ApiClient.get('/auth/profile/', auth: true);
    if (response.success && response.data != null) {
      final userData = response.data!.containsKey('id')
          ? response.data!
          : response.data!['user'];
      if (userData != null) {
        await StorageService.write(
          StorageService.keyUserProfile,
          jsonEncode(userData),
        );
      }
    }
    return response;
  }

  /// Logout: clear all stored tokens and user data.
  static Future<void> logout() async {
    await StorageService.deleteAll();
    await AvatarCacheService.clearAvatar();
  }

  /// Update user demographic data.
  static Future<ApiResponse> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiClient.patch('/auth/update/', body: data);

    if (response.success && response.data != null) {
      final userData = response.data!.containsKey('id')
          ? response.data!
          : response.data!['user'];
      if (userData != null) {
        await StorageService.write(
          StorageService.keyUserProfile,
          jsonEncode(userData),
        );
      }
    }
    return response;
  }

  /// Update user profile avatar.
  static Future<ApiResponse> updateProfileAvatar(XFile image) async {
    // Read the mime type or default to image/jpeg
    String? mimeType = image.mimeType;
    if (mimeType == null) {
      final ext = image.name.split('.').last.toLowerCase();
      if (ext == 'png') {
        mimeType = 'image/png';
      } else {
        mimeType = 'image/jpeg';
      }
    }

    String filename = image.name;
    if (!filename.contains('.')) {
      filename += mimeType == 'image/png' ? '.png' : '.jpg';
    }

    final bytes = await image.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'avatar',
      bytes,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    );

    final response = await ApiClient.patchMultipart(
      '/auth/update/',
      files: [multipartFile],
    );

    if (response.success && response.data != null) {
      final userData = response.data!.containsKey('id')
          ? response.data!
          : response.data!['user'];
      if (userData != null) {
        await StorageService.write(
          StorageService.keyUserProfile,
          jsonEncode(userData),
        );
      }
    }

    return response;
  }
}
