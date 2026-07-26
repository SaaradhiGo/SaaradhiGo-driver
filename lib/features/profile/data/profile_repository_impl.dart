import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/driver_profile.dart';
import '../domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<DriverProfile> fetchProfile() async {
    final data = await _api.get(ApiEndpoints.driverProfile);
    return DriverProfile.fromJson(data);
  }

  @override
  Future<List<Vehicle>> fetchVehicles() async {
    final list = await _api.getList(ApiEndpoints.vehicles);
    return list
        .whereType<Map<String, dynamic>>()
        .map(Vehicle.fromJson)
        .toList(growable: false);
  }
}
