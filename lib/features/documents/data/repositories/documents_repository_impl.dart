import '../../../../domain/models/driver_document_model.dart';
import '../../domain/repositories/documents_repository.dart';
import '../data_sources/documents_remote_data_source.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final DocumentsRemoteDataSource remoteDataSource;

  DocumentsRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<DriverDocumentModel>> getComplianceDocuments() async {
    final profile = await remoteDataSource.getProfileForDocuments();
    final vehicle = profile.activeVehicleDetails;

    final documents = <DriverDocumentModel>[];

    // 1. Driving Licence Front
    documents.add(
      DriverDocumentModel(
        id: 'license_front',
        documentTypeKey: 'license_doc',
        title: 'Driving Licence (Front)',
        fileUrl: profile.licenseDoc,
        expiryDate: profile.licenseExpiry,
        status: DriverDocumentModel.computeStatus(
          url: profile.licenseDoc,
          expiry: profile.licenseExpiry,
          rawStatus: profile.kycStatus,
        ),
      ),
    );

    // 2. Driving Licence Back
    documents.add(
      DriverDocumentModel(
        id: 'license_back',
        documentTypeKey: 'license_doc_back',
        title: 'Driving Licence (Back)',
        fileUrl: profile.licenseDocBack,
        expiryDate: profile.licenseExpiry,
        status: DriverDocumentModel.computeStatus(
          url: profile.licenseDocBack,
          expiry: profile.licenseExpiry,
          rawStatus: profile.kycStatus,
        ),
      ),
    );

    // 3. Vehicle Registration (RC)
    final rcDoc = vehicle?['rc_doc']?.toString();
    final rcExpiryStr = vehicle?['rc_expiry']?.toString();
    final rcExpiry = rcExpiryStr != null
        ? DateTime.tryParse(rcExpiryStr)
        : null;
    documents.add(
      DriverDocumentModel(
        id: 'vehicle_rc',
        documentTypeKey: 'rc_doc',
        title: 'Vehicle Registration (RC)',
        fileUrl: rcDoc,
        expiryDate: rcExpiry,
        status: DriverDocumentModel.computeStatus(
          url: rcDoc,
          expiry: rcExpiry,
          rawStatus: vehicle?['status']?.toString(),
        ),
      ),
    );

    // 4. Commercial Insurance
    final insuranceDoc = vehicle?['insurance_doc']?.toString();
    final insuranceExpiryStr = vehicle?['insurance_expiry']?.toString();
    final insuranceExpiry = insuranceExpiryStr != null
        ? DateTime.tryParse(insuranceExpiryStr)
        : null;
    documents.add(
      DriverDocumentModel(
        id: 'vehicle_insurance',
        documentTypeKey: 'insurance_doc',
        title: 'Commercial Insurance',
        fileUrl: insuranceDoc,
        expiryDate: insuranceExpiry,
        status: DriverDocumentModel.computeStatus(
          url: insuranceDoc,
          expiry: insuranceExpiry,
          rawStatus: vehicle?['status']?.toString(),
        ),
      ),
    );

    // 5. Vehicle Permit & Fitness
    final fitnessDoc = vehicle?['fitness_doc']?.toString();
    final fitnessExpiryStr = vehicle?['fitness_expiry']?.toString();
    final fitnessExpiry = fitnessExpiryStr != null
        ? DateTime.tryParse(fitnessExpiryStr)
        : null;
    documents.add(
      DriverDocumentModel(
        id: 'vehicle_fitness',
        documentTypeKey: 'fitness_doc',
        title: 'Vehicle Permit & Fitness',
        fileUrl: fitnessDoc,
        expiryDate: fitnessExpiry,
        status: DriverDocumentModel.computeStatus(
          url: fitnessDoc,
          expiry: fitnessExpiry,
          rawStatus: vehicle?['status']?.toString(),
        ),
      ),
    );

    return documents;
  }

  @override
  Future<void> updateDocumentKey({
    required String documentTypeKey,
    required String s3Key,
    DateTime? expiryDate,
    int? vehicleId,
  }) async {
    if (documentTypeKey == 'license_doc' ||
        documentTypeKey == 'license_doc_back') {
      final payload = <String, dynamic>{documentTypeKey: s3Key};
      if (expiryDate != null) {
        payload['license_expiry'] = expiryDate
            .toIso8601String()
            .split('T')
            .first;
      }
      await remoteDataSource.updateDriverDocument(payload);
    } else if (vehicleId != null) {
      final payload = <String, dynamic>{documentTypeKey: s3Key};
      if (expiryDate != null) {
        if (documentTypeKey == 'insurance_doc') {
          payload['insurance_expiry'] = expiryDate
              .toIso8601String()
              .split('T')
              .first;
        } else if (documentTypeKey == 'rc_doc') {
          payload['rc_expiry'] = expiryDate.toIso8601String().split('T').first;
        }
      }
      await remoteDataSource.updateVehicleDocument(vehicleId, payload);
    } else {
      // Fallback: driver document update
      await remoteDataSource.updateDriverDocument({documentTypeKey: s3Key});
    }
  }
}
