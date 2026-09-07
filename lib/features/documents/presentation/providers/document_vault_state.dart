import '../../../../domain/models/driver_document_model.dart';

enum DocumentVaultStatus { initial, loading, success, empty, error, refreshing }

class DocumentVaultState {
  final DocumentVaultStatus status;
  final List<DriverDocumentModel> documents;
  final int verifiedCount;
  final int actionRequiredCount;
  final bool isUploading;
  final double uploadProgress;
  final String? uploadingDocumentKey;
  final String? errorMessage;

  const DocumentVaultState({
    this.status = DocumentVaultStatus.initial,
    this.documents = const [],
    this.verifiedCount = 0,
    this.actionRequiredCount = 0,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadingDocumentKey,
    this.errorMessage,
  });

  bool get isLoading => status == DocumentVaultStatus.loading;
  bool get isRefreshing => status == DocumentVaultStatus.refreshing;
  bool get isEmpty => status == DocumentVaultStatus.empty;
  bool get hasError => status == DocumentVaultStatus.error;

  DocumentVaultState copyWith({
    DocumentVaultStatus? status,
    List<DriverDocumentModel>? documents,
    int? verifiedCount,
    int? actionRequiredCount,
    bool? isUploading,
    double? uploadProgress,
    String? uploadingDocumentKey,
    String? errorMessage,
  }) {
    return DocumentVaultState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      actionRequiredCount: actionRequiredCount ?? this.actionRequiredCount,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadingDocumentKey: uploadingDocumentKey ?? this.uploadingDocumentKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
