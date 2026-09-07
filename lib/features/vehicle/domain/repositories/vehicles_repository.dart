import '../../../../domain/models/vehicle_model.dart';

abstract class VehiclesRepository {
  /// Fetches all vehicles registered under the authenticated driver.
  Future<List<VehicleModel>> getVehicles();

  /// Sets a specific vehicle as the driver's active vehicle.
  Future<void> switchActiveVehicle(int vehicleId);

  /// Updates vehicle properties or documents.
  Future<VehicleModel> updateVehicle(int vehicleId, Map<String, dynamic> data);
}
