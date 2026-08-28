import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/uploads/presigned_upload_providers.dart';
import '../../data/data_sources/onboarding_remote_data_source.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/repositories/i_onboarding_repository.dart';
import '../../domain/use_cases/submit_bank_details_use_case.dart';
import '../../domain/use_cases/submit_licence_use_case.dart';
import '../../domain/use_cases/submit_personal_details_use_case.dart';
import '../../domain/use_cases/submit_vehicle_use_case.dart';
import '../../domain/use_cases/update_vehicle_use_case.dart';
import 'onboarding_notifier.dart';
import 'onboarding_state.dart';
export 'onboarding_state.dart';

final onboardingRemoteDataSourceProvider = Provider<OnboardingRemoteDataSource>(
  (ref) {
    return OnboardingRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
  },
);

final onboardingRepositoryProvider = Provider<IOnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(
    ref.watch(onboardingRemoteDataSourceProvider),
    uploadService: ref.watch(presignedUploadServiceProvider),
    presignedUploadsEnabled: () => ref.read(presignedUploadsFlagProvider),
  );
});

final submitPersonalDetailsUseCaseProvider =
    Provider<SubmitPersonalDetailsUseCase>((ref) {
      return SubmitPersonalDetailsUseCase(
        ref.watch(onboardingRepositoryProvider),
      );
    });

final submitBankDetailsUseCaseProvider = Provider<SubmitBankDetailsUseCase>((
  ref,
) {
  return SubmitBankDetailsUseCase(ref.watch(onboardingRepositoryProvider));
});

final submitVehicleUseCaseProvider = Provider<SubmitVehicleUseCase>((ref) {
  return SubmitVehicleUseCase(ref.watch(onboardingRepositoryProvider));
});

final submitLicenceUseCaseProvider = Provider<SubmitLicenceUseCase>((ref) {
  return SubmitLicenceUseCase(ref.watch(onboardingRepositoryProvider));
});

final updateVehicleUseCaseProvider = Provider<UpdateVehicleUseCase>((ref) {
  return UpdateVehicleUseCase(ref.watch(onboardingRepositoryProvider));
});

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(() {
      return OnboardingNotifier();
    });
