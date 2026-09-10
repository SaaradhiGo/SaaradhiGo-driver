import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/i_onboarding_repository.dart';

class SubmitBankDetailsUseCase {
  final IOnboardingRepository repository;

  SubmitBankDetailsUseCase(this.repository);

  Future<Either<Failure, void>> execute(Map<String, dynamic> bankData) async {
    return await repository.updateBankDetails(bankData);
  }
}
