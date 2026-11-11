import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../domain/models/vehicle_model.dart';

abstract class VehiclesRemoteDataSource {
  Future<List<VehicleModel>> getVehicles();
  Future<void> switchActiveVehicle(int vehicleId);
  Future<VehicleModel> updateVehicle(int vehicleId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> addVehicleWithKeys(Map<String, dynamic> body);
}

class VehiclesRemoteDataSourceImpl implements VehiclesRemoteDataSource {
  final Dio dio;

  VehiclesRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'] as List<dynamic>? ?? [];
      }
      if (data is List) {
        return data;
      }
      if (responseData.containsKey('results')) {
        return responseData['results'] as List<dynamic>? ?? [];
      }
    }
    if (responseData is List) {
      return responseData;
    }
    return [];
  }

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
  Future<List<VehicleModel>> getVehicles() async {
    final response = await dio.get(ApiEndpoints.driverVehicles);
    final list = _extractList(response.data);
    return list
        .map((e) => VehicleModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> switchActiveVehicle(int vehicleId) async {
    await dio.patch(
      ApiEndpoints.driverUpdate,
      data: {'active_vehicle': vehicleId},
    );
  }

  @override
  Future<VehicleModel> updateVehicle(
    int vehicleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.patch(
      ApiEndpoints.updateVehicle(vehicleId.toString()),
      data: data,
    );
    final map = _extractData(response.data);
    return VehicleModel.fromJson(map);
  }

  @override
  Future<Map<String, dynamic>> addVehicleWithKeys(
    Map<String, dynamic> body,
  ) async {
    final response = await dio.post(ApiEndpoints.addVehicle, data: body);
    return _extractData(response.data);
  }
}
