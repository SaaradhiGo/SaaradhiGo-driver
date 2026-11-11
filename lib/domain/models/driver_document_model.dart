import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_document_model.freezed.dart';
part 'driver_document_model.g.dart';

enum DocumentStatus {
  verified,
  pending,
  renewalDue,
  expired,
  rejected,
  missing;

  String get label {
    switch (this) {
      case DocumentStatus.verified:
        return 'VERIFIED';
      case DocumentStatus.pending:
        return 'PENDING';
      case DocumentStatus.renewalDue:
        return 'RENEWAL DUE';
      case DocumentStatus.expired:
        return 'EXPIRED';
      case DocumentStatus.rejected:
        return 'REJECTED';
      case DocumentStatus.missing:
        return 'NOT UPLOADED';
    }
  }

  bool get isActionRequired =>
      this == DocumentStatus.renewalDue ||
      this == DocumentStatus.expired ||
      this == DocumentStatus.rejected ||
      this == DocumentStatus.missing;
}

@freezed
abstract class DriverDocumentModel with _$DriverDocumentModel {
  const DriverDocumentModel._();

  const factory DriverDocumentModel({
    required String id,
    required String documentTypeKey,
    required String title,
    String? fileUrl,
    DateTime? expiryDate,
    @Default(DocumentStatus.missing) DocumentStatus status,
    String? rejectionReason,
    @Default(true) bool isMandatory,
  }) = _DriverDocumentModel;

  factory DriverDocumentModel.fromJson(Map<String, dynamic> json) =>
      _$DriverDocumentModelFromJson(json);

  /// Helper to calculate status based on URL, expiry date, and optional status string.
  static DocumentStatus computeStatus({
    required String? url,
    required DateTime? expiry,
    String? rawStatus,
    String? rejectionReason,
  }) {
    if (rejectionReason != null && rejectionReason.isNotEmpty) {
      return DocumentStatus.rejected;
    }
    if (url == null || url.trim().isEmpty) {
      return DocumentStatus.missing;
    }
    final s = (rawStatus ?? '').toLowerCase();
    if (s == 'rejected') return DocumentStatus.rejected;

    if (expiry != null) {
      final now = DateTime.now();
      if (expiry.isBefore(now)) {
        return DocumentStatus.expired;
      }
      if (expiry.difference(now).inDays <= 30) {
        return DocumentStatus.renewalDue;
      }
    }

    if (s == 'pending' || s == 'submitted') {
      return DocumentStatus.pending;
    }

    return DocumentStatus.verified;
  }
}
