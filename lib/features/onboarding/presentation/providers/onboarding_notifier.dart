import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/picked_document.dart';
import '../../data/models/vehicle_request_dto.dart';
import '../../domain/use_cases/submit_bank_details_use_case.dart';
import '../../domain/use_cases/submit_licence_use_case.dart';
import '../../domain/use_cases/submit_personal_details_use_case.dart';
import '../../domain/use_cases/submit_vehicle_use_case.dart';
import 'onboarding_providers.dart';

class OnboardingNotifier extends Notifier<OnboardingState> {
  late SubmitPersonalDetailsUseCase _submitPersonalDetailsUseCase;
  late SubmitBankDetailsUseCase _submitBankDetailsUseCase;
  late SubmitVehicleUseCase _submitVehicleUseCase;
  late SubmitLicenceUseCase _submitLicenceUseCase;
  bool _disposed = false;

  @override
  OnboardingState build() {
    ref.onDispose(() => _disposed = true);
    _submitPersonalDetailsUseCase = ref.watch(
      submitPersonalDetailsUseCaseProvider,
    );
    _submitBankDetailsUseCase = ref.watch(submitBankDetailsUseCaseProvider);
    _submitVehicleUseCase = ref.watch(submitVehicleUseCaseProvider);
    _submitLicenceUseCase = ref.watch(submitLicenceUseCaseProvider);
    return const OnboardingState.initial();
  }

  bool get _isBusy =>
      state is OnboardingStateLoading || state is OnboardingStateUploading;

  /// Cancels an in-flight S3 upload (called when a hosting screen is disposed)
  /// so the PUT does not keep running in the background.
  void cancelUpload() {
    if (_isBusy) {
      ref.read(onboardingRepositoryProvider).cancelActiveUpload();
    }
  }

  Future<void> submitPersonalDetails(
    Map<String, dynamic> data, {
    PickedDocument? avatar,
  }) async {
    if (_isBusy) return;
    state = const OnboardingState.loading();
    final result = await _submitPersonalDetailsUseCase.execute(
      data,
      avatar: avatar,
      onProgress: avatar == null
          ? null
          : _progressReporter('Uploading profile photo…'),
    );
    state = result.fold(
      (failure) => OnboardingState.error(failure.message),
      (_) => const OnboardingState.success(),
    );
  }

  Future<void> submitBankDetails(Map<String, dynamic> bankData) async {
    if (_isBusy) return;
    state = const OnboardingState.loading();
    final result = await _submitBankDetailsUseCase.execute(bankData);
    state = result.fold(
      (failure) => OnboardingState.error(failure.message),
      (_) => const OnboardingState.success(),
    );
  }

  Future<void> submitVehicle(VehicleRequestDto vehicleDto) async {
    if (_isBusy) return;
    state = const OnboardingState.loading();
    final result = await _submitVehicleUseCase.execute(
      vehicleDto,
      onProgress: _progressReporter('Uploading vehicle documents…'),
    );
    state = result.fold(
      (failure) => OnboardingState.error(failure.message),
      (_) => const OnboardingState.success(),
    );
  }

  Future<void> submitLicence(
    String licenseNumber,
    String licenseExpiry,
    PickedDocument document, {
    PickedDocument? backDocument,
  }) async {
    if (_isBusy) return;
    state = const OnboardingState.loading();
    final result = await _submitLicenceUseCase.execute(
      licenseNumber,
      licenseExpiry,
      document,
      backDocument: backDocument,
      onProgress: _progressReporter('Uploading driving licence…'),
    );
    state = result.fold(
      (failure) => OnboardingState.error(failure.message),
      (_) => const OnboardingState.success(),
    );
  }

  /// Reports S3 PUT byte progress as an [OnboardingStateUploading] state so
  /// screens can render a determinate progress bar.
  void Function(int sent, int total)? _progressReporter(String label) {
    return (int sent, int total) {
      final safeTotal = total <= 0 ? 1 : total;
      final progress = (sent / safeTotal).clamp(0.0, 1.0);
      if (!_disposed) {
        state = OnboardingState.uploading(progress: progress, label: label);
      }
    };
  }
}
