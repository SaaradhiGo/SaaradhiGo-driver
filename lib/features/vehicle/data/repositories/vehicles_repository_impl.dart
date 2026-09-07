import '../../../../domain/models/vehicle_model.dart';
import '../../domain/repositories/vehicles_repository.dart';
import '../data_sources/vehicles_remote_data_source.dart';

class VehiclesRepositoryImpl implements VehiclesRepository {
  final VehiclesRemoteDataSource remoteDataSource;

  VehiclesRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<VehicleModel>> getVehicles() async {
    return await remoteDataSource.getVehicles();
  }

  @override
  Future<void> switchActiveVehicle(int vehicleId) async {
    await remoteDataSource.switchActiveVehicle(vehicleId);
  }

  @override
  Future<VehicleModel> updateVehicle(
    int vehicleId,
    Map<String, dynamic> data,
  ) async {
    return await remoteDataSource.updateVehicle(vehicleId, data);
  }
}
