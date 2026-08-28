import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/uploads/upload_kind.dart';
import '../../data/models/picked_document.dart';
import '../../data/models/vehicle_request_dto.dart';

export '../../../../core/uploads/upload_kind.dart' show UploadProgressCallback;

abstract class IOnboardingRepository {
  Future<Either<Failure, void>> updatePersonalDetails(
    Map<String, dynamic> data,
  );
  Future<Either<Failure, void>> updateAvatar(
    PickedDocument document, {
    UploadProgressCallback? onProgress,
  });
  Future<Either<Failure, void>> updateBankDetails(Map<String, dynamic> data);
  Future<Either<Failure, void>> addVehicle(
    VehicleRequestDto vehicleDto, {
    UploadProgressCallback? onProgress,
  });
  Future<Either<Failure, void>> updateDrivingLicence(
    String licenseNumber,
    String licenseExpiry,
    PickedDocument document, {
    // Optional back-side photo. Submitted as `license_doc_back`
    // ([CONFIRMED] API_Documentation_V2 §3.2 — file or presigned S3 key,
    // not required for KYC).
    PickedDocument? backDocument,
    UploadProgressCallback? onProgress,
  });

  /// PATCHes a vehicle with a partial JSON payload. Document fields must
  /// already be presigned object keys (e.g. `{'rc_doc': '<key>'}`).
  Future<Either<Failure, void>> updateVehicle(
    String vehicleId,
    Map<String, dynamic> partialUpdate,
  );

  /// Cancels any in-flight S3 upload started by this repository (used when a
  /// screen hosting the upload is disposed).
  void cancelActiveUpload();
}
