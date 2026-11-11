import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

@freezed
sealed class OnboardingState with _$OnboardingState {
  const factory OnboardingState.initial() = OnboardingStateInitial;
  const factory OnboardingState.loading() = OnboardingStateLoading;
  const factory OnboardingState.uploading({
    required double progress,
    required String label,
  }) = OnboardingStateUploading;
  const factory OnboardingState.success() = OnboardingStateSuccess;
  const factory OnboardingState.error(String message) = OnboardingStateError;
}
