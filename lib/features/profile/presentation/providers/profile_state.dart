import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../domain/models/driver_profile_model.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = ProfileStateInitial;
  const factory ProfileState.loading() = ProfileStateLoading;
  const factory ProfileState.loaded(DriverProfileModel profile) =
      ProfileStateLoaded;
  const factory ProfileState.error(String message) = ProfileStateError;
}
