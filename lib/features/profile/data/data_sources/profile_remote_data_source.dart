import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../domain/models/driver_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<DriverProfileModel> getDriverProfile();

  /// Presigned flow: submit the already-uploaded S3 object key as plain JSON.
  Future<void> updateAvatarKey(String avatarKey);

  /// Legacy multipart upload (feature flag OFF). Kept compiled until the
  /// `presignedUploads` flag is removed.
  Future<void> updateAvatarMultipart(Uint8List bytes, String? fileName);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  static const _uploadTimeout = Duration(seconds: 120);

  final Dio dio;

  ProfileRemoteDataSourceImpl(this.dio);

  @override
  Future<DriverProfileModel> getDriverProfile() async {
    final response = await dio.get(ApiEndpoints.driverProfile);

    // According to docs, API returns: {"status": "success", "data": {"approved": true, "kyc_status": "approved", ...}}
    // Assuming the Dio interceptor unpacks "data" if configured, or we need to unpack it here.
    // Let's check how auth repo unpacks it.

    // For safety, let's assume interceptor unpacks it or it returns data directly based on previous conventions.
    // Let's just use response.data['data'] if it exists, otherwise response.data
    final responseData = response.data;
    final dynamic rawData =
        responseData is Map && responseData.containsKey('data')
        ? responseData['data']
        : responseData;
    final Map<String, dynamic> dataMap = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    return DriverProfileModel.fromJson(dataMap);
  }

  @override
  Future<void> updateAvatarKey(String avatarKey) async {
    await dio.patch(ApiEndpoints.updateProfile, data: {'avatar': avatarKey});
  }

  @override
  Future<void> updateAvatarMultipart(Uint8List bytes, String? fileName) async {
    final formData = FormData.fromMap(<String, dynamic>{
      'avatar': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    await dio.patch(
      ApiEndpoints.updateProfile,
      data: formData,
      options: Options(
        sendTimeout: _uploadTimeout,
        receiveTimeout: _uploadTimeout,
      ),
    );
  }
}
