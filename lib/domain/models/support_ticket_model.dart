import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';
import 'support_message_model.dart';

part 'support_ticket_model.freezed.dart';
part 'support_ticket_model.g.dart';

/// A support ticket listed by `GET /support/tickets/`.
///
/// Status values follow the PRD (OPEN / IN PROGRESS / RESOLVED / CLOSED) and
/// are kept as strings because the ticket serializers are not pinned in the
/// API documentation; the UI maps known values to a [StatusBadge]-friendly
/// presentation and treats anything else as neutral.
@freezed
abstract class SupportTicketModel with _$SupportTicketModel {
  const SupportTicketModel._();

  const factory SupportTicketModel({
    @JsonKey(fromJson: intFromJson) @Default(0) int id,
    String? subject,
    String? description,
    String? category,
    String? status,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'messages', defaultValue: <SupportMessageModel>[])
    @Default(<SupportMessageModel>[])
    List<SupportMessageModel> messages,
  }) = _SupportTicketModel;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketModelFromJson(json);
}
