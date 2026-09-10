import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';

part 'support_message_model.freezed.dart';
part 'support_message_model.g.dart';

// The support thread may emit the role under either key depending on the
// serializer (`sender_role` for tickets created from an incident, `sender` on
// plain threads). Prefer the explicit role key.
Object? _readSenderRole(Map json, String key) =>
    json['sender_role'] ?? json['sender'];

/// One line in a support ticket thread. The reply UI distinguishes the
/// driver's own messages (`senderRole == 'driver'`) from agent replies so
/// bubbles can be rendered left/right.
///
/// The API contract (POST `/support/tickets/<ticket_id>/messages/`) documents
/// no response body, so decoding is intentionally tolerant.
@freezed
abstract class SupportMessageModel with _$SupportMessageModel {
  const factory SupportMessageModel({
    @JsonKey(fromJson: intFromJson) @Default(0) int id,
    @JsonKey(readValue: _readSenderRole) String? senderRole,
    String? body,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'is_system', fromJson: boolFromJson)
    @Default(false)
    bool isSystem,
  }) = _SupportMessageModel;

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) =>
      _$SupportMessageModelFromJson(json);
}
