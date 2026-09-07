import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/driver_document_model.dart';
import 'package:saaradhigo_driver/features/documents/domain/repositories/documents_repository.dart';
import 'package:saaradhigo_driver/features/documents/presentation/providers/document_vault_providers.dart';

class StubDocumentsRepository implements DocumentsRepository {
  bool shouldThrow = false;
  List<DriverDocumentModel> docsToReturn = [
    DriverDocumentModel(
      id: 'license_front',
      documentTypeKey: 'license_doc',
      title: 'Driving Licence (Front)',
      fileUrl: 'https://s3.amazonaws.com/bucket/license_front.jpg',
      expiryDate: DateTime.now().add(const Duration(days: 365)),
      status: DocumentStatus.verified,
    ),
    DriverDocumentModel(
      id: 'vehicle_insurance',
      documentTypeKey: 'insurance_doc',
      title: 'Commercial Insurance',
      fileUrl: 'https://s3.amazonaws.com/bucket/insurance.jpg',
      expiryDate: DateTime.now().add(const Duration(days: 10)),
      status: DocumentStatus.renewalDue,
    ),
    const DriverDocumentModel(
      id: 'vehicle_rc',
      documentTypeKey: 'rc_doc',
      title: 'Vehicle Registration (RC)',
      status: DocumentStatus.missing,
    ),
  ];

  String? lastUpdatedKey;
  String? lastS3Key;

  @override
  Future<List<DriverDocumentModel>> getComplianceDocuments() async {
    if (shouldThrow) throw Exception('Documents error');
    return docsToReturn;
  }

  @override
  Future<void> updateDocumentKey({
    required String documentTypeKey,
    required String s3Key,
    DateTime? expiryDate,
    int? vehicleId,
  }) async {
    if (shouldThrow) throw Exception('Update key error');
    lastUpdatedKey = documentTypeKey;
    lastS3Key = s3Key;
  }
}

void main() {
  late StubDocumentsRepository stubRepo;
  late ProviderContainer container;

  setUp(() {
    stubRepo = StubDocumentsRepository();
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(stubRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial fetch parses documents and computes Bento counts', () async {
    final notifier = container.read(documentVaultNotifierProvider.notifier);
    await notifier.fetchDocuments();

    final state = container.read(documentVaultNotifierProvider);
    expect(state.status, DocumentVaultStatus.success);
    expect(state.documents.length, 3);
    expect(state.verifiedCount, 1);
    // Insurance (renewalDue) and RC (missing) both require action
    expect(state.actionRequiredCount, 2);
  });

  test('fetchDocuments handles empty document list', () async {
    stubRepo.docsToReturn = [];
    final notifier = container.read(documentVaultNotifierProvider.notifier);
    await notifier.fetchDocuments();

    final state = container.read(documentVaultNotifierProvider);
    expect(state.status, DocumentVaultStatus.empty);
    expect(state.documents, isEmpty);
    expect(state.verifiedCount, 0);
    expect(state.actionRequiredCount, 0);
  });

  test('fetchDocuments handles error', () async {
    stubRepo.shouldThrow = true;
    final notifier = container.read(documentVaultNotifierProvider.notifier);
    await notifier.fetchDocuments();

    final state = container.read(documentVaultNotifierProvider);
    expect(state.status, DocumentVaultStatus.error);
    expect(state.errorMessage, isNotNull);
  });
}
