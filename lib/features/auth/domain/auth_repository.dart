import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/failures.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepository(dioClient);
});

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<void> requestOtp(String phoneNumber) async {
    try {
      final responseData = await _dioClient.request(
        () => _dioClient.dio.post(
          ApiEndpoints.requestOtp,
          data: {'phone_number': phoneNumber, 'role': 'driver'},
        ),
      );

      if (responseData['status'] != 'success') {
        throw Exception(responseData['message'] ?? 'Failed to request OTP');
      }
    } on Failure {
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    try {
      final responseData = await _dioClient.request(
        () => _dioClient.dio.post(
          ApiEndpoints.login,
          data: {
            'phone_number': phoneNumber,
            'otp': otp,
            'device_token': 'dummy_device_token',
          },
        ),
      );

      if (responseData['status'] == 'success') {
        final token = responseData['data']['token'];
        final refreshToken = responseData['data']['refresh_token'];

        await SecureStorageService.saveTokens(
          accessToken: token,
          refreshToken: refreshToken,
        );
      } else {
        throw Exception(responseData['message'] ?? 'Failed to verify OTP');
      }
    } on Failure {
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    await SecureStorageService.clearTokens();
  }
}
