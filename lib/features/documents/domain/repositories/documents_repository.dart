import '../../../../domain/models/driver_document_model.dart';

abstract class DocumentsRepository {
  /// Fetches compliance documents parsed from the driver's profile and active vehicle.
  Future<List<DriverDocumentModel>> getComplianceDocuments();

  /// Updates a document with a presigned uploaded S3 key.
  Future<void> updateDocumentKey({
    required String documentTypeKey,
    required String s3Key,
    DateTime? expiryDate,
    int? vehicleId,
  });
}
