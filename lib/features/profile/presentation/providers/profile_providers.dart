import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/uploads/presigned_upload_providers.dart';
import '../../data/data_sources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/i_profile_repository.dart';
import 'profile_notifier.dart';
import 'profile_state.dart';

export 'profile_state.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  return ProfileRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
});

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(profileRemoteDataSourceProvider),
    uploadService: ref.watch(presignedUploadServiceProvider),
    presignedUploadsEnabled: () => ref.read(presignedUploadsFlagProvider),
  );
});

final driverProfileNotifierProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(() {
      return ProfileNotifier();
    });
