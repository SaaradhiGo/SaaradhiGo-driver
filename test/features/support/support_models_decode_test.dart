import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/chat_message_model.dart';
import 'package:saaradhigo_driver/domain/models/sos_alert_model.dart';
import 'package:saaradhigo_driver/domain/models/support_message_model.dart';
import 'package:saaradhigo_driver/domain/models/support_ticket_model.dart';

/// Decode tests for the Phase 7 models (chat, SOS alert, support ticket and
/// support message). The backend API docs (API_Documentation_V2.md §4.14, §6.1,
/// §8.x) pin no response bodies, so these models are intentionally tolerant —
/// these tests lock in the tolerant behaviour against realistic payload shapes.
void main() {
  group('ChatMessageModel.fromJson', () {
    test('decodes the documented WS/chat history shape', () {
      final message = ChatMessageModel.fromJson(const {
        'id': 12,
        'sender_role': 'rider',
        'body': 'I am at the north gate',
        'created_at': '2026-04-07T10:00:00Z',
        'is_system': false,
      });

      expect(message.id, 12);
      expect(message.senderRole, 'rider');
      expect(message.body, 'I am at the north gate');
      expect(message.createdAt, '2026-04-07T10:00:00Z');
      expect(message.isSystem, isFalse);
    });

    test('is tolerant of numeric id and missing fields', () {
      final message = ChatMessageModel.fromJson(const {
        'sender_role': 'driver',
        'body': 'ok',
      });

      expect(message.id, 0);
      expect(message.senderRole, 'driver');
      expect(message.isSystem, isFalse);
    });

    test('driver outbound optimistic copy has senderRole driver', () {
      final message = ChatMessageModel(
        id: 0,
        senderRole: 'driver',
        body: 'Arriving now',
        createdAt: '2026-04-07T10:05:00Z',
      );
      expect(message.senderRole, 'driver');
      expect(message.isSystem, isFalse);
    });
  });

  group('SupportTicketModel.fromJson', () {
    test('decodes a ticket with nested message thread', () {
      final ticket = SupportTicketModel.fromJson(const {
        'id': 42,
        'subject': 'Fare adjustment',
        'description': 'Trip fare was incorrect.',
        'category': 'Payment Dispute',
        'status': 'IN_PROGRESS',
        'created_at': '2026-04-07T10:00:00Z',
        'updated_at': '2026-04-08T10:00:00Z',
        'messages': [
          {
            'id': 1,
            'sender': 'driver',
            'body': 'Please review.',
            'created_at': '2026-04-07T10:00:00Z',
          },
        ],
      });

      expect(ticket.id, 42);
      expect(ticket.subject, 'Fare adjustment');
      expect(ticket.category, 'Payment Dispute');
      expect(ticket.status, 'IN_PROGRESS');
      expect(ticket.messages, hasLength(1));
      expect(ticket.messages.first.body, 'Please review.');
      expect(ticket.messages.first.senderRole, 'driver');
    });

    test('defaults messages and numeric fields when payload is missing', () {
      final ticket = SupportTicketModel.fromJson(const <String, dynamic>{});
      expect(ticket.id, 0);
      expect(ticket.messages, isEmpty);
      expect(ticket.status, isNull);
    });
  });

  group('SupportMessageModel.fromJson', () {
    test('reads sender_role over sender when both keys are present', () {
      final message = SupportMessageModel.fromJson(const {
        'id': 3,
        'sender_role': 'agent',
        'sender': 'driver',
        'body': 'Reviewed.',
        'created_at': '2026-04-08T10:00:00Z',
        'is_system': false,
      });

      expect(message.senderRole, 'agent');
    });

    test('falls back to sender key when sender_role is absent', () {
      final message = SupportMessageModel.fromJson(const {
        'id': 4,
        'sender': 'driver',
        'body': 'Thanks',
      });
      expect(message.senderRole, 'driver');
    });

    test('decodes a system note', () {
      final message = SupportMessageModel.fromJson(const {
        'body': 'Ticket opened by driver',
        'is_system': true,
      });
      expect(message.isSystem, isTrue);
    });
  });

  group('SosAlertModel.fromJson', () {
    test('decodes the documented SOS acknowledgement', () {
      final alert = SosAlertModel.fromJson(const {
        'id': 77,
        'trip_id': 101,
        'status': 'acknowledged',
        'latitude': 17.385,
        'longitude': 78.486,
        'message': 'Help dispatched',
        'created_at': '2026-04-07T10:00:00Z',
      });

      expect(alert.id, 77);
      expect(alert.tripId, 101);
      expect(alert.status, 'acknowledged');
      expect(alert.latitude, 17.385);
      expect(alert.longitude, 78.486);
    });

    test('tolerates empty/missing payload', () {
      final alert = SosAlertModel.fromJson(const <String, dynamic>{});
      expect(alert.id, 0);
      expect(alert.tripId, isNull);
      // The doubleFromJson helper coerces missing coordinates to 0.0 (not
      // null) so the UI never sees an unparsable double at runtime.
      expect(alert.latitude, 0.0);
      expect(alert.longitude, 0.0);
    });
  });
}
