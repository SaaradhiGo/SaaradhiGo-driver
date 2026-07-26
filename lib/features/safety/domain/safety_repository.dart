/// A support ticket as the driver sees it (`/support/tickets/`).
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.state,
    this.category,
    this.createdAt,
    this.messages = const [],
  });

  final int id;
  final String subject;
  final String state;
  final String? category;
  final DateTime? createdAt;
  final List<SupportMessage> messages;

  bool get isOpen => state != 'closed' && state != 'resolved';

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    return SupportTicket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      subject: json['subject']?.toString() ?? 'Support request',
      state: json['state']?.toString() ?? json['status']?.toString() ?? 'open',
      category: json['category']?.toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      messages: rawMessages is List
          ? rawMessages
              .whereType<Map<String, dynamic>>()
              .map(SupportMessage.fromJson)
              .toList(growable: false)
          : const [],
    );
  }
}

class SupportMessage {
  const SupportMessage({
    required this.body,
    required this.isStaff,
    this.author,
    this.createdAt,
  });

  final String body;
  final bool isStaff;
  final String? author;
  final DateTime? createdAt;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender_role']?.toString() ?? json['author_role']?.toString();
    return SupportMessage(
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      isStaff: sender == 'staff' || sender == 'admin' || json['is_staff'] == true,
      author: json['author']?.toString() ?? json['author_name']?.toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}

abstract class SafetyRepository {
  /// Raise an SOS. `initiated_by: 'driver'` is what routes this to the ops
  /// SOS queue as a driver event and picks the right notification path.
  ///
  /// The server acks within ~1s and dispatches alerts asynchronously, so the
  /// UI can show "help is on the way" as soon as this returns.
  Future<int> raiseSos({
    required String eventType,
    int? tripId,
    double? lat,
    double? lng,
    double? accuracyM,
    String? note,
  });

  Future<List<SupportTicket>> fetchTickets();

  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    String? category,
    int? tripId,
  });

  Future<SupportTicket> fetchTicket(int id);

  Future<void> addMessage({required int ticketId, required String body});
}
