import '../../../../domain/models/chat_message_model.dart';
import '../../../../domain/models/sos_alert_model.dart';
import '../../../../domain/models/support_message_model.dart';
import '../../../../domain/models/support_ticket_model.dart';
import '../../domain/repositories/support_repository.dart';
import '../data_sources/support_remote_data_source.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteDataSource remoteDataSource;

  SupportRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ChatMessageModel>> getTripChatHistory(String tripId) async {
    return await remoteDataSource.getTripChatHistory(tripId);
  }

  @override
  Future<SosAlertModel> raiseSos({
    int? tripId,
    required double latitude,
    required double longitude,
  }) async {
    return await remoteDataSource.raiseSos(
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<List<SupportTicketModel>> listTickets() async {
    return await remoteDataSource.listTickets();
  }

  @override
  Future<SupportTicketModel> createTicket({
    required String category,
    required String subject,
    required String description,
    int? tripId,
  }) async {
    return await remoteDataSource.createTicket(
      category: category,
      subject: subject,
      description: description,
      tripId: tripId,
    );
  }

  @override
  Future<SupportTicketModel> getTicketDetail(int ticketId) async {
    return await remoteDataSource.getTicketDetail(ticketId);
  }

  @override
  Future<SupportMessageModel> addTicketMessage(
    int ticketId,
    String body,
  ) async {
    return await remoteDataSource.addTicketMessage(ticketId, body);
  }

  @override
  Future<SupportTicketModel> closeTicket(int ticketId) async {
    return await remoteDataSource.closeTicket(ticketId);
  }

  @override
  Future<void> updateEmergencyContact(String value) async {
    await remoteDataSource.updateEmergencyContact(value);
  }
}
