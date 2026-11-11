import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../domain/models/driver_profile_model.dart';

abstract class DocumentsRemoteDataSource {
  Future<DriverProfileModel> getProfileForDocuments();
  Future<void> updateDriverDocument(Map<String, dynamic> payload);
  Future<void> updateVehicleDocument(
    int vehicleId,
    Map<String, dynamic> payload,
  );
}

class DocumentsRemoteDataSourceImpl implements DocumentsRemoteDataSource {
  final Dio dio;

  DocumentsRemoteDataSourceImpl(this.dio);

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic> &&
        responseData.containsKey('data') &&
        responseData['data'] != null) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    return <String, dynamic>{};
  }

  @override
  Future<DriverProfileModel> getProfileForDocuments() async {
    final response = await dio.get(ApiEndpoints.driverProfile);
    final map = _extractData(response.data);
    return DriverProfileModel.fromJson(map);
  }

  @override
  Future<void> updateDriverDocument(Map<String, dynamic> payload) async {
    await dio.patch(ApiEndpoints.driverUpdate, data: payload);
  }

  @override
  Future<void> updateVehicleDocument(
    int vehicleId,
    Map<String, dynamic> payload,
  ) async {
    await dio.patch(
      ApiEndpoints.updateVehicle(vehicleId.toString()),
      data: payload,
    );
  }
}
