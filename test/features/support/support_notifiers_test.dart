import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/connectivity_provider.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';
import 'package:saaradhigo_driver/domain/models/chat_message_model.dart';
import 'package:saaradhigo_driver/domain/models/sos_alert_model.dart';
import 'package:saaradhigo_driver/domain/models/support_message_model.dart';
import 'package:saaradhigo_driver/domain/models/support_ticket_model.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/features/auth/domain/auth_repository.dart';
import 'package:saaradhigo_driver/features/support/data/data_sources/trip_chat_consumer.dart';
import 'package:saaradhigo_driver/features/support/domain/repositories/support_repository.dart';
import 'package:saaradhigo_driver/features/support/presentation/providers/support_providers.dart';

import '../../core/network/test_websocket_channel.dart';

/// Stub for the AuthRepository dependency of [AuthNotifier]. The SOS notifier
/// mirrors the saved emergency contact into the authenticated user, which reads
/// the auth state; overriding this keeps the default Dio-based repository (and
/// its network layer) out of these unit tests.
class StubAuthRepository implements AuthRepository {
  @override
  Future<void> requestOtp(String phoneNumber) async {}

  @override
  Future<UserModel?> verifyOtp(String phoneNumber, String otp) async => null;

  @override
  Future<UserModel?> emailLogin({
    required String email,
    required String password,
  }) async =>
      null;

  @override
  Future<String> requestPasswordReset(String email) async => 'sent';

  @override
  Future<void> logout() async {}
}

/// Stub repository so the notifiers can be tested in isolation from the Dio
/// network layer. Each controller can independently simulate failure.
class StubSupportRepository implements SupportRepository {
  bool failHistory = false;
  bool failCreate = false;
  bool failDetail = false;
  bool failReply = false;
  bool failClose = false;
  bool failSos = false;
  bool failUpdateContact = false;

  List<ChatMessageModel> history = [];
  List<SupportTicketModel> tickets = [];
  SupportTicketModel detail = const SupportTicketModel();
  SosAlertModel alert = const SosAlertModel();

  String? lastSosTripId;
  double? lastLatitude;
  double? lastLongitude;
  String? lastEmergencyContact;

  @override
  Future<List<ChatMessageModel>> getTripChatHistory(String tripId) async {
    if (failHistory) throw Exception('Network error');
    return history;
  }

  @override
  Future<SosAlertModel> raiseSos({
    int? tripId,
    required double latitude,
    required double longitude,
  }) async {
    if (failSos) throw Exception('Network error');
    lastSosTripId = tripId?.toString();
    lastLatitude = latitude;
    lastLongitude = longitude;
    return alert;
  }

  @override
  Future<List<SupportTicketModel>> listTickets() async {
    if (failHistory) throw Exception('Network error');
    return tickets;
  }

  @override
  Future<SupportTicketModel> createTicket({
    required String category,
    required String subject,
    required String description,
    int? tripId,
  }) async {
    if (failCreate) throw Exception('Network error');
    final ticket = SupportTicketModel(
      id: 99,
      subject: subject,
      description: description,
      category: category,
      status: 'OPEN',
    );
    tickets = [ticket, ...tickets];
    return ticket;
  }

  @override
  Future<SupportTicketModel> getTicketDetail(int ticketId) async {
    if (failDetail) throw Exception('Network error');
    return detail;
  }

  @override
  Future<SupportMessageModel> addTicketMessage(
    int ticketId,
    String body,
  ) async {
    if (failReply) throw Exception('Network error');
    return SupportMessageModel(id: 5, senderRole: 'driver', body: body);
  }

  @override
  Future<SupportTicketModel> closeTicket(int ticketId) async {
    if (failClose) throw Exception('Network error');
    return const SupportTicketModel(id: 9, status: 'CLOSED');
  }

  @override
  Future<void> updateEmergencyContact(String value) async {
    if (failUpdateContact) throw Exception('Network error');
    lastEmergencyContact = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late StubSupportRepository stub;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    stub = StubSupportRepository();
    // The chat notifier opens a TripChatConsumer bound to a real WebSocket
    // service; override the factory so `open()` runs against an in-memory
    // channel (mirroring the driver_location_consumer tests).
    container = ProviderContainer(
      overrides: [
        // The chat notifier pauses/resumes its socket on connectivity changes;
        // pin the flag so no platform connectivity plugin is probed in tests.
        isOnlineNetworkProvider.overrideWithValue(true),
        supportRepositoryProvider.overrideWithValue(stub),
        authRepositoryProvider.overrideWithValue(StubAuthRepository()),
        tripChatConsumerFactoryProvider.overrideWithValue((tripId) {
          final channel = TestWebSocketChannel();
          return TripChatConsumer(
            tripId: tripId,
            tokenReader: () async => 'jwt',
            wsBaseUrlReader: () => 'wss://api.example/',
            serviceFactory: (urlBuilder) => WebSocketService(
              urlBuilder: urlBuilder,
              channelFactory: (_) => channel,
            ),
          );
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  group('SupportTicketsNotifier', () {
    test('initial state has empty tickets and is not loading', () {
      final state = container.read(supportTicketsNotifierProvider);
      expect(state.tickets, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('loadTickets populates the ticket list', () async {
      stub.tickets = const [
        SupportTicketModel(id: 1, subject: 'Fare issue', status: 'OPEN'),
      ];

      await container
          .read(supportTicketsNotifierProvider.notifier)
          .loadTickets();

      final state = container.read(supportTicketsNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.tickets, hasLength(1));
      expect(state.tickets.first.subject, 'Fare issue');
      expect(state.errorMessage, isNull);
    });

    test('loadTickets surfaces an error message on failure', () async {
      stub.failHistory = true;

      await container
          .read(supportTicketsNotifierProvider.notifier)
          .loadTickets();

      final state = container.read(supportTicketsNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('Could not load your tickets'));
    });

    test('submitTicket adds the created ticket and exposes its id', () async {
      final notifier = container.read(supportTicketsNotifierProvider.notifier);
      await notifier.submitTicket(
        category: 'Vehicle Collision',
        subject: 'Vehicle Collision',
        description: 'Hit a divider.',
      );

      final state = container.read(supportTicketsNotifierProvider);
      expect(state.isSubmitting, isFalse);
      expect(state.createdTicketId, 99);
      expect(state.tickets, hasLength(1));
      expect(state.tickets.first.id, 99);
    });

    test('submitTicket surfaces an error message on failure', () async {
      stub.failCreate = true;
      final notifier = container.read(supportTicketsNotifierProvider.notifier);
      await notifier.submitTicket(
        category: 'Other',
        subject: 'Other',
        description: 'details',
      );

      final state = container.read(supportTicketsNotifierProvider);
      expect(state.createdTicketId, isNull);
      expect(state.errorMessage, contains('Could not submit your report'));
    });
  });

  group('SupportTicketDetailNotifier', () {
    test('open loads the ticket thread', () async {
      stub.detail = const SupportTicketModel(
        id: 7,
        subject: 'Fare dispute',
        status: 'OPEN',
        messages: [
          SupportMessageModel(senderRole: 'agent', body: 'We are looking.'),
        ],
      );

      await container
          .read(supportTicketDetailNotifierProvider.notifier)
          .open(7);

      final state = container.read(supportTicketDetailNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.ticket?.id, 7);
      expect(state.ticket?.messages, hasLength(1));
    });

    test('sendReply posts and refreshes the thread', () async {
      stub.detail = const SupportTicketModel(
        id: 7,
        subject: 'Fare dispute',
        status: 'OPEN',
      );

      final notifier = container.read(
        supportTicketDetailNotifierProvider.notifier,
      );
      await notifier.open(7);
      await notifier.sendReply('Please check again.');

      final state = container.read(supportTicketDetailNotifierProvider);
      expect(state.isSendingReply, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('closeTicket replaces the ticket with the closed one', () async {
      final notifier = container.read(
        supportTicketDetailNotifierProvider.notifier,
      );
      await notifier.open(9);

      await notifier.closeTicket();

      final state = container.read(supportTicketDetailNotifierProvider);
      expect(state.isClosing, isFalse);
      expect(state.ticket?.status, 'CLOSED');
    });
  });

  group('SosNotifier', () {
    test('raiseSos posts an alert and sets a confirmation', () async {
      stub.alert = const SosAlertModel(id: 88, status: 'acknowledged');

      await container
          .read(sosNotifierProvider.notifier)
          .raiseSos(tripId: 101, latitude: 17.385, longitude: 78.486);

      final state = container.read(sosNotifierProvider);
      expect(state.isRaising, isFalse);
      expect(stub.lastSosTripId, '101');
      expect(stub.lastLatitude, 17.385);
      expect(stub.lastLongitude, 78.486);
      expect(state.confirmationMessage, contains('Reference #88'));
    });

    test('raiseSos surfaces a recoverable error on failure', () async {
      stub.failSos = true;

      await container
          .read(sosNotifierProvider.notifier)
          .raiseSos(tripId: null, latitude: 17.385, longitude: 78.486);

      final state = container.read(sosNotifierProvider);
      expect(state.isRaising, isFalse);
      expect(state.confirmationMessage, isNull);
      expect(state.errorMessage, isNotNull);
    });

    test('updateEmergencyContact saves the trimmed contact', () async {
      await container
          .read(sosNotifierProvider.notifier)
          .updateEmergencyContact('  +91 98200 00000  ');

      final state = container.read(sosNotifierProvider);
      expect(stub.lastEmergencyContact, '+91 98200 00000');
      expect(state.isSavingContact, isFalse);
      expect(state.contactSavedMessage, isNotNull);
    });

    test('updateEmergencyContact surfaces an error on failure', () async {
      stub.failUpdateContact = true;

      await container
          .read(sosNotifierProvider.notifier)
          .updateEmergencyContact('+91 98200 00000');

      final state = container.read(sosNotifierProvider);
      expect(state.isSavingContact, isFalse);
      expect(state.errorMessage, contains('Could not save the emergency'));
    });
  });

  group('TripChatNotifier', () {
    test('open loads history and clears the history loading flag', () async {
      stub.history = const [
        ChatMessageModel(id: 1, senderRole: 'rider', body: 'hi'),
      ];

      await container.read(tripChatNotifierProvider.notifier).open(101);

      final state = container.read(tripChatNotifierProvider);
      expect(state.isLoadingHistory, isFalse);
      expect(state.messages, hasLength(1));
      expect(state.messages.first.body, 'hi');
    });

    test('open tolerates a history failure without a fatal error', () async {
      stub.failHistory = true;

      await container.read(tripChatNotifierProvider.notifier).open(101);

      final state = container.read(tripChatNotifierProvider);
      // History failure is non-fatal: live socket can still start a chat.
      expect(state.errorMessage, isNotNull);
      expect(state.isLoadingHistory, isFalse);
    });
  });
}
