import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/uploads/upload_kind.dart';
import '../../../../domain/models/driver_profile_model.dart';

abstract class IProfileRepository {
  Future<Either<Failure, DriverProfileModel>> getDriverProfile();

  /// Uploads the avatar via the presigned direct-to-S3 flow (or legacy
  /// multipart when the feature flag is off) and PATCHes the resulting object
  /// key to `/auth/update/`.
  Future<Either<Failure, void>> updateAvatar({
    required Uint8List bytes,
    required String fileName,
    UploadProgressCallback? onProgress,
  });
}
