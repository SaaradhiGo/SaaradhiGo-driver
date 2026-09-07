import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/uploads/presigned_upload_providers.dart';
import '../../../../core/uploads/upload_kind.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/repositories/documents_repository.dart';
import 'document_vault_providers.dart';

class DocumentVaultNotifier extends Notifier<DocumentVaultState> {
  late DocumentsRepository _repository;

  @override
  DocumentVaultState build() {
    try {
      _repository = ref.watch(documentsRepositoryProvider);
    } catch (_) {
      // Test environment fallback
    }
    return const DocumentVaultState();
  }

  Future<void> fetchDocuments({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    if (refresh) {
      state = state.copyWith(status: DocumentVaultStatus.refreshing);
    } else {
      state = state.copyWith(status: DocumentVaultStatus.loading);
    }

    try {
      final docs = await _repository.getComplianceDocuments();

      final verified = docs.where((d) => d.status.name == 'verified').length;
      final actionReq = docs.where((d) => d.status.isActionRequired).length;

      if (docs.isEmpty) {
        state = state.copyWith(
          status: DocumentVaultStatus.empty,
          documents: [],
          verifiedCount: 0,
          actionRequiredCount: 0,
        );
      } else {
        state = state.copyWith(
          status: DocumentVaultStatus.success,
          documents: docs,
          verifiedCount: verified,
          actionRequiredCount: actionReq,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: DocumentVaultStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  UploadKind _kindForDoc(String key) {
    switch (key) {
      case 'license_doc':
        return UploadKind.licenseDoc;
      case 'license_doc_back':
        return UploadKind.licenseDocBack;
      case 'rc_doc':
      default:
        return UploadKind.rcDoc;
    }
  }

  Future<bool> reuploadDocument({
    required String documentTypeKey,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    DateTime? expiryDate,
    int? vehicleId,
  }) async {
    final kind = _kindForDoc(documentTypeKey);

    final validationError = UploadValidator.validate(
      kind: kind,
      mimeType: mimeType,
      byteLength: bytes.length,
    );

    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.1,
      uploadingDocumentKey: documentTypeKey,
      errorMessage: null,
    );

    try {
      final uploadService = ref.read(presignedUploadServiceProvider);
      final result = await uploadService.upload(
        kind: kind,
        bytes: bytes,
        mimeType: mimeType,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );

      // Submit S3 key to backend
      await _repository.updateDocumentKey(
        documentTypeKey: documentTypeKey,
        s3Key: result.key,
        expiryDate: expiryDate,
        vehicleId: vehicleId,
      );

      // Refresh global profile so other parts of the app have updated docs
      await ref.read(driverProfileNotifierProvider.notifier).fetchProfile();

      // Re-fetch documents to refresh UI
      await fetchDocuments(refresh: true);

      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        uploadingDocumentKey: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        uploadingDocumentKey: null,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}
