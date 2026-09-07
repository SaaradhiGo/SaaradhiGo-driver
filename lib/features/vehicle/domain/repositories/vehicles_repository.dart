import '../../../../core/uploads/upload_kind.dart';
import '../../../../domain/models/vehicle_model.dart';
import '../../../onboarding/data/models/vehicle_request_dto.dart';

abstract class VehiclesRepository {
  /// Fetches all vehicles registered under the authenticated driver.
  Future<List<VehicleModel>> getVehicles();

  /// Sets a specific vehicle as the driver's active vehicle.
  Future<void> switchActiveVehicle(int vehicleId);

  /// Updates vehicle properties or documents.
  Future<VehicleModel> updateVehicle(int vehicleId, Map<String, dynamic> data);

  /// Registers a new vehicle with optional direct S3 document uploads and auto-activation.
  Future<VehicleModel> addVehicle(
    VehicleRequestDto dto, {
    UploadProgressCallback? onProgress,
  });
}
