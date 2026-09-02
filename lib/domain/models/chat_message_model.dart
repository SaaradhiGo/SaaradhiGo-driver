import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

/// A single line in the in-trip passenger chat
/// (`ws/ride/trip/<id>/chat/`). The WebSocket `message` broadcast and the REST
/// history (`GET /ride/trip/<id>/chat/`) share this shape.
///
/// `sender_role` is `driver` (this driver) or `rider` (the passenger). System
/// notifications (e.g. "Trip started") are marked `is_system`. All fields are
/// tolerant because the API documentation does not pin the response body.
@freezed
abstract class ChatMessageModel with _$ChatMessageModel {
  const factory ChatMessageModel({
    @JsonKey(fromJson: intFromJson) @Default(0) int id,
    @JsonKey(name: 'sender_role') String? senderRole,
    String? body,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'is_system', fromJson: boolFromJson)
    @Default(false)
    bool isSystem,
  }) = _ChatMessageModel;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);
}
