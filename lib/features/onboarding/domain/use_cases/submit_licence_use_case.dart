import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/picked_document.dart';
import '../repositories/i_onboarding_repository.dart';

class SubmitLicenceUseCase {
  final IOnboardingRepository repository;

  SubmitLicenceUseCase(this.repository);

  Future<Either<Failure, void>> execute(
    String licenseNumber,
    String licenseExpiry,
    PickedDocument document, {
    PickedDocument? backDocument,
    UploadProgressCallback? onProgress,
  }) async {
    return await repository.updateDrivingLicence(
      licenseNumber,
      licenseExpiry,
      document,
      backDocument: backDocument,
      onProgress: onProgress,
    );
  }
}
