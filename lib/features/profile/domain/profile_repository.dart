import 'driver_profile.dart';

abstract class ProfileRepository {
  Future<DriverProfile> fetchProfile();
  Future<List<Vehicle>> fetchVehicles();
}
