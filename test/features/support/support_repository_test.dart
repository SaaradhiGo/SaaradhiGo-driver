import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/chat_message_model.dart';
import 'package:saaradhigo_driver/domain/models/sos_alert_model.dart';
import 'package:saaradhigo_driver/domain/models/support_message_model.dart';
import 'package:saaradhigo_driver/domain/models/support_ticket_model.dart';
import 'package:saaradhigo_driver/features/support/data/data_sources/support_remote_data_source.dart';
import 'package:saaradhigo_driver/features/support/data/repositories/support_repository_impl.dart';

/// Fake data source that lets each repository test control every return value
/// and record the arguments the repository forwards.
class FakeSupportRemoteDataSource implements SupportRemoteDataSource {
  List<ChatMessageModel> historyToReturn = [];
  SosAlertModel alertToReturn = const SosAlertModel();
  List<SupportTicketModel> ticketsToReturn = [];
  SupportTicketModel ticketToReturn = const SupportTicketModel();
  SupportMessageModel messageToReturn = const SupportMessageModel();

  String? lastChatTripId;
  int? lastTripId;
  double? lastLatitude;
  double? lastLongitude;
  int? lastTicketId;
  String? lastMessageBody;
  String? lastEmergencyContact;

  @override
  Future<List<ChatMessageModel>> getTripChatHistory(String tripId) async {
    lastChatTripId = tripId;
    return historyToReturn;
  }

  @override
  Future<SosAlertModel> raiseSos({
    int? tripId,
    required double latitude,
    required double longitude,
  }) async {
    lastTripId = tripId;
    lastLatitude = latitude;
    lastLongitude = longitude;
    return alertToReturn;
  }

  @override
  Future<List<SupportTicketModel>> listTickets() async {
    return ticketsToReturn;
  }

  @override
  Future<SupportTicketModel> createTicket({
    required String category,
    required String subject,
    required String description,
    int? tripId,
  }) async {
    lastTripId = tripId;
    return ticketToReturn;
  }

  @override
  Future<SupportTicketModel> getTicketDetail(int ticketId) async {
    lastTicketId = ticketId;
    return ticketToReturn;
  }

  @override
  Future<SupportMessageModel> addTicketMessage(
    int ticketId,
    String body,
  ) async {
    lastTicketId = ticketId;
    lastMessageBody = body;
    return messageToReturn;
  }

  @override
  Future<SupportTicketModel> closeTicket(int ticketId) async {
    lastTicketId = ticketId;
    return ticketToReturn;
  }

  @override
  Future<void> updateEmergencyContact(String value) async {
    lastEmergencyContact = value;
  }
}

void main() {
  late FakeSupportRemoteDataSource dataSource;
  late SupportRepositoryImpl repository;

  setUp(() {
    dataSource = FakeSupportRemoteDataSource();
    repository = SupportRepositoryImpl(dataSource);
  });

  group('SupportRepositoryImpl', () {
    test('getTripChatHistory passes through the trip id string', () async {
      dataSource.historyToReturn = const [
        ChatMessageModel(id: 1, senderRole: 'rider', body: 'hi'),
      ];

      final history = await repository.getTripChatHistory('77');

      expect(dataSource.lastChatTripId, '77');
      expect(history, hasLength(1));
      expect(history.first.senderRole, 'rider');
    });

    test('raiseSos forwards trip id and coordinates', () async {
      dataSource.alertToReturn = const SosAlertModel(
        id: 88,
        status: 'acknowledged',
      );

      final alert = await repository.raiseSos(
        tripId: 101,
        latitude: 17.385,
        longitude: 78.486,
      );

      expect(dataSource.lastTripId, 101);
      expect(dataSource.lastLatitude, 17.385);
      expect(dataSource.lastLongitude, 78.486);
      expect(alert.id, 88);
    });

    test('listTickets returns the tickets from the data source', () async {
      dataSource.ticketsToReturn = const [
        SupportTicketModel(id: 1, subject: 'Fare dispute'),
      ];

      final tickets = await repository.listTickets();

      expect(tickets, hasLength(1));
      expect(tickets.first.subject, 'Fare dispute');
    });

    test('createTicket forwards incident fields and trip id', () async {
      dataSource.ticketToReturn = const SupportTicketModel(id: 42);

      final ticket = await repository.createTicket(
        category: 'Vehicle Collision',
        subject: 'Vehicle Collision',
        description: 'Hit a divider.',
        tripId: 101,
      );

      expect(dataSource.lastTripId, 101);
      expect(ticket.id, 42);
    });

    test('getTicketDetail forwards the ticket id', () async {
      await repository.getTicketDetail(77);
      expect(dataSource.lastTicketId, 77);
    });

    test('addTicketMessage forwards ticket id and body', () async {
      await repository.addTicketMessage(9, 'Please review');
      expect(dataSource.lastTicketId, 9);
      expect(dataSource.lastMessageBody, 'Please review');
    });

    test('closeTicket forwards the ticket id', () async {
      await repository.closeTicket(9);
      expect(dataSource.lastTicketId, 9);
    });

    test('updateEmergencyContact forwards the trimmed value', () async {
      await repository.updateEmergencyContact('+91 98200 00000');
      expect(dataSource.lastEmergencyContact, '+91 98200 00000');
    });
  });
}
