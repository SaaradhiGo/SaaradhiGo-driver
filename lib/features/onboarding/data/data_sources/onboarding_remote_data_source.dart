import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/picked_document.dart';
import '../models/vehicle_request_dto.dart';

abstract class OnboardingRemoteDataSource {
  Future<Map<String, dynamic>> updatePersonalDetails(Map<String, dynamic> data);

  // --- Legacy multipart uploads (feature flag OFF) -------------------------
  Future<Map<String, dynamic>> updateAvatarMultipart(PickedDocument document);
  Future<Map<String, dynamic>> addVehicle(VehicleRequestDto vehicleDto);
  Future<Map<String, dynamic>> updateDrivingLicenceMultipart({
    required String licenseNumber,
    required String licenseExpiry,
    required PickedDocument document,
    PickedDocument? backDocument,
  });

  // --- Presigned direct-to-S3 key submissions (feature flag ON) ------------
  Future<Map<String, dynamic>> updateAvatarWithKey(String avatarKey);
  Future<Map<String, dynamic>> addVehicleWithKeys(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateDrivingLicenceWithKeys(
    Map<String, dynamic> body,
  );

  // --- Plain JSON updates --------------------------------------------------
  Future<Map<String, dynamic>> updateBankDetails(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateVehicle(
    String vehicleId,
    Map<String, dynamic> body,
  );

  /// Marks an existing vehicle as the driver's active vehicle via
  /// `PATCH /driver/driver/update/ {"active_vehicle": <driver's vehicle id>}`
  /// (API doc §3.2).
  Future<Map<String, dynamic>> setActiveVehicle(int vehicleId);
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  // File uploads can take longer than the global 30s receiveTimeout on slow
  // networks, so they use a relaxed limit.
  static const _uploadTimeout = Duration(seconds: 120);

  final Dio dio;

  OnboardingRemoteDataSourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> updatePersonalDetails(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.patch(ApiEndpoints.updateProfile, data: data);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateAvatarWithKey(String avatarKey) async {
    final response = await dio.patch(
      ApiEndpoints.updateProfile,
      data: {'avatar': avatarKey},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateAvatarMultipart(
    PickedDocument document,
  ) async {
    final formData = FormData.fromMap(await _avatarMultipartFields(document));
    final response = await dio.patch(
      ApiEndpoints.updateProfile,
      data: formData,
      options: Options(
        sendTimeout: _uploadTimeout,
        receiveTimeout: _uploadTimeout,
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _avatarMultipartFields(
    PickedDocument document,
  ) async {
    if (document.bytes != null && document.bytes!.isNotEmpty) {
      return {
        'avatar': MultipartFile.fromBytes(
          document.bytes!,
          filename: document.name,
        ),
      };
    }
    return {
      'avatar': await MultipartFile.fromFile(
        document.path!,
        filename: document.name,
      ),
    };
  }

  @override
  Future<Map<String, dynamic>> updateBankDetails(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.patch(
      ApiEndpoints.updateBankDetails,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> addVehicleWithKeys(
    Map<String, dynamic> body,
  ) async {
    final response = await dio.post(ApiEndpoints.addVehicle, data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> addVehicle(VehicleRequestDto vehicleDto) async {
    final fields = <String, dynamic>{
      'vehicle_number': vehicleDto.registrationNumber,
      'vehicle_type': vehicleDto.vehicleType,
      'make': vehicleDto.make,
      'model': vehicleDto.model,
      'year': vehicleDto.year,
      'color': vehicleDto.color,
    };

    final document = vehicleDto.rcDocument;
    if (document != null && document.isAvailable) {
      fields['rc_doc'] = await _documentToMultipartFile(document);
    }

    // API_Documentation_V2 §3.6: `vehicle_pic` is an accepted multipart file
    // on the create endpoint for the legacy (non-presigned) flow.
    final pic = vehicleDto.vehiclePicDocument;
    if (pic != null && pic.isAvailable) {
      fields['vehicle_pic'] = await _documentToMultipartFile(pic);
    }

    final formData = FormData.fromMap(fields);
    final response = await dio.post(
      ApiEndpoints.addVehicle,
      data: formData,
      options: Options(
        sendTimeout: _uploadTimeout,
        receiveTimeout: _uploadTimeout,
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateDrivingLicenceWithKeys(
    Map<String, dynamic> body,
  ) async {
    final response = await dio.patch(ApiEndpoints.driverUpdate, data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateDrivingLicenceMultipart({
    required String licenseNumber,
    required String licenseExpiry,
    required PickedDocument document,
    PickedDocument? backDocument,
  }) async {
    final formData = FormData.fromMap(<String, dynamic>{
      'license_number': licenseNumber,
      'license_expiry': licenseExpiry,
      'license_doc': await _documentToMultipartFile(document),
      if (backDocument != null && backDocument.isAvailable)
        'license_doc_back': await _documentToMultipartFile(backDocument),
    });
    final response = await dio.patch(
      ApiEndpoints.driverUpdate,
      data: formData,
      options: Options(
        sendTimeout: _uploadTimeout,
        receiveTimeout: _uploadTimeout,
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateVehicle(
    String vehicleId,
    Map<String, dynamic> body,
  ) async {
    final response = await dio.patch(
      ApiEndpoints.updateVehicle(vehicleId),
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> setActiveVehicle(int vehicleId) async {
    final response = await dio.patch(
      ApiEndpoints.driverUpdate,
      data: {'active_vehicle': vehicleId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<MultipartFile> _documentToMultipartFile(PickedDocument document) {
    if (document.bytes != null && document.bytes!.isNotEmpty) {
      return Future.value(
        MultipartFile.fromBytes(document.bytes!, filename: document.name),
      );
    }
    return MultipartFile.fromFile(document.path!, filename: document.name);
  }
}
