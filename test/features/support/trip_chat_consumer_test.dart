import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';
import 'package:saaradhigo_driver/domain/models/chat_message_model.dart';
import 'package:saaradhigo_driver/features/support/data/data_sources/trip_chat_consumer.dart';

import '../../core/network/test_websocket_channel.dart';

void main() {
  test('builds the chat endpoint without duplicating /ws or the token', () {
    final plainBase = TripChatConsumer.buildUri(
      wsBaseUrl: 'wss://api.example/',
      tripId: 101,
      token: 'a-token',
    );
    final baseIncludingWs = TripChatConsumer.buildUri(
      wsBaseUrl: 'wss://api.example/ws/',
      tripId: 101,
      token: 'a-token',
    );

    expect(plainBase.path, '/ws/ride/trip/101/chat/');
    expect(baseIncludingWs.path, '/ws/ride/trip/101/chat/');
    expect(plainBase.queryParameters['token'], 'a-token');
  });

  test('parses all documented inbound event types', () {
    final established = TripChatConsumer.parseEvent(const {
      'type': 'connection_established',
      'trip_id': 101,
      'role': 'driver',
    });
    expect(established, isA<TripChatConnectionEstablished>());
    expect((established as TripChatConnectionEstablished).tripId, 101);
    expect(established.role, 'driver');

    final message = TripChatConsumer.parseEvent(const {
      'type': 'message',
      'id': 12,
      'sender_role': 'rider',
      'body': 'Where are you?',
      'created_at': '2026-04-07T10:00:00Z',
      'is_system': false,
    });
    expect(message, isA<TripChatMessageReceived>());
    final received = message as TripChatMessageReceived;
    expect(received.message, isA<ChatMessageModel>());
    expect(received.senderRole, 'rider');
    expect(received.body, 'Where are you?');

    final error = TripChatConsumer.parseEvent(const {
      'type': 'error',
      'message': 'Trip already completed.',
    });
    expect(error, isA<TripChatErrorEvent>());
    expect((error as TripChatErrorEvent).message, 'Trip already completed.');

    expect(
      TripChatConsumer.parseEvent(const {'type': 'future_event'}),
      isA<TripChatUnknownEvent>(),
    );
  });

  test('sends the documented send/read_all wire actions', () async {
    final channel = TestWebSocketChannel();
    final consumer = TripChatConsumer(
      tripId: 101,
      tokenReader: () async => 'jwt',
      wsBaseUrlReader: () => 'wss://api.example/',
      serviceFactory: (urlBuilder) => WebSocketService(
        urlBuilder: urlBuilder,
        channelFactory: (_) => channel,
      ),
    );
    addTearDown(consumer.dispose);

    consumer.connect();
    await pumpEventQueue();
    consumer.sendMessage('  Hello there  ');
    consumer.markAllRead();

    final sent = channel.sink.sent
        .map((raw) => jsonDecode(raw as String))
        .toList();
    expect(sent, [
      {'action': 'send', 'body': 'Hello there'},
      {'action': 'read_all'},
    ]);
  });

  test('ignores empty sends', () async {
    final channel = TestWebSocketChannel();
    final consumer = TripChatConsumer(
      tripId: 101,
      tokenReader: () async => 'jwt',
      wsBaseUrlReader: () => 'wss://api.example/',
      serviceFactory: (urlBuilder) => WebSocketService(
        urlBuilder: urlBuilder,
        channelFactory: (_) => channel,
      ),
    );
    addTearDown(consumer.dispose);

    consumer.connect();
    await pumpEventQueue();
    consumer.sendMessage('   ');

    expect(channel.sink.sent, isEmpty);
  });
}
