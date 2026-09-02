import '../../../../domain/models/chat_message_model.dart';
import '../../../../domain/models/sos_alert_model.dart';
import '../../../../domain/models/support_message_model.dart';
import '../../../../domain/models/support_ticket_model.dart';

/// Contract the Support/Safety presentation layer depends on. Kept free of
/// framework types so notifiers can be unit-tested against a stub.
abstract class SupportRepository {
  Future<List<ChatMessageModel>> getTripChatHistory(String tripId);

  Future<SosAlertModel> raiseSos({
    int? tripId,
    required double latitude,
    required double longitude,
  });

  Future<List<SupportTicketModel>> listTickets();

  Future<SupportTicketModel> createTicket({
    required String category,
    required String subject,
    required String description,
    int? tripId,
  });

  Future<SupportTicketModel> getTicketDetail(int ticketId);

  Future<SupportMessageModel> addTicketMessage(int ticketId, String body);

  Future<SupportTicketModel> closeTicket(int ticketId);

  Future<void> updateEmergencyContact(String value);
}
