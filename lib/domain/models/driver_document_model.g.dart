// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DriverDocumentModel _$DriverDocumentModelFromJson(Map<String, dynamic> json) =>
    _DriverDocumentModel(
      id: json['id'] as String,
      documentTypeKey: json['documentTypeKey'] as String,
      title: json['title'] as String,
      fileUrl: json['fileUrl'] as String?,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      status:
          $enumDecodeNullable(_$DocumentStatusEnumMap, json['status']) ??
          DocumentStatus.missing,
      rejectionReason: json['rejectionReason'] as String?,
      isMandatory: json['isMandatory'] as bool? ?? true,
    );

Map<String, dynamic> _$DriverDocumentModelToJson(
  _DriverDocumentModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'documentTypeKey': instance.documentTypeKey,
  'title': instance.title,
  'fileUrl': instance.fileUrl,
  'expiryDate': instance.expiryDate?.toIso8601String(),
  'status': _$DocumentStatusEnumMap[instance.status]!,
  'rejectionReason': instance.rejectionReason,
  'isMandatory': instance.isMandatory,
};

const _$DocumentStatusEnumMap = {
  DocumentStatus.verified: 'verified',
  DocumentStatus.pending: 'pending',
  DocumentStatus.renewalDue: 'renewalDue',
  DocumentStatus.expired: 'expired',
  DocumentStatus.rejected: 'rejected',
  DocumentStatus.missing: 'missing',
};
