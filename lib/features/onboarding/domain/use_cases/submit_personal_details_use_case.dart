import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/picked_document.dart';
import '../repositories/i_onboarding_repository.dart';

class SubmitPersonalDetailsUseCase {
  final IOnboardingRepository repository;

  SubmitPersonalDetailsUseCase(this.repository);

  /// Submits demographics (`PATCH /auth/update/` §1.4) and, when an avatar
  /// was picked, uploads it right after so step 1 leaves a complete profile.
  Future<Either<Failure, void>> execute(
    Map<String, dynamic> data, {
    PickedDocument? avatar,
    UploadProgressCallback? onProgress,
  }) async {
    final detailsResult = await repository.updatePersonalDetails(data);
    return detailsResult.fold((failure) => Left(failure), (_) async {
      final pickedAvatar = avatar;
      if (pickedAvatar == null || !pickedAvatar.isAvailable) {
        return const Right(null);
      }
      return repository.updateAvatar(pickedAvatar, onProgress: onProgress);
    });
  }
}
