import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_onboarding_repository.dart';

/// PATCHes an existing driver vehicle with a partial JSON payload.
/// Document fields must already be presigned object keys.
class UpdateVehicleUseCase {
  final IOnboardingRepository repository;

  UpdateVehicleUseCase(this.repository);

  Future<Either<Failure, void>> execute(
    String vehicleId,
    Map<String, dynamic> partialUpdate,
  ) async {
    return await repository.updateVehicle(vehicleId, partialUpdate);
  }
}
