import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/i_profile_repository.dart';
import 'profile_providers.dart';

class ProfileNotifier extends Notifier<ProfileState> {
  late IProfileRepository _repository;

  @override
  ProfileState build() {
    _repository = ref.watch(profileRepositoryProvider);
    return const ProfileState.initial();
  }

  bool get _isBusy => state is ProfileStateLoading;

  Future<void> fetchProfile() async {
    state = const ProfileState.loading();
    final result = await _repository.getDriverProfile();
    state = result.fold(
      (failure) => ProfileState.error(failure.message),
      (profile) => ProfileState.loaded(profile),
    );
  }

  /// Changes the avatar: uploads the file (presigned direct-to-S3) and, on
  /// success, refetches the profile so the freshly signed display URL is used.
  Future<void> changeAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_isBusy) return;
    state = const ProfileState.loading();
    final result = await _repository.updateAvatar(
      bytes: bytes,
      fileName: fileName,
    );
    var failed = false;
    result.fold((failure) {
      failed = true;
      state = ProfileState.error(failure.message);
    }, (_) {});
    // Refetch instead of caching the display URL: server-signed URLs expire
    // after ~15 minutes, so entities must be re-fetched to refresh them.
    if (!failed) {
      await fetchProfile();
    }
  }
}
