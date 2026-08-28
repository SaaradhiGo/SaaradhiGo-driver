import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/vehicle_request_dto.dart';
import '../repositories/i_onboarding_repository.dart';

class SubmitVehicleUseCase {
  final IOnboardingRepository repository;

  SubmitVehicleUseCase(this.repository);

  Future<Either<Failure, void>> execute(
    VehicleRequestDto vehicleDto, {
    UploadProgressCallback? onProgress,
  }) async {
    return await repository.addVehicle(vehicleDto, onProgress: onProgress);
  }
}
