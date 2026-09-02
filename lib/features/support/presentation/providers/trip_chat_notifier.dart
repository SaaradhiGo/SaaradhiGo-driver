import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/chat_message_model.dart';
import '../../data/data_sources/trip_chat_consumer.dart';
import 'support_providers.dart';

/// Drives one trip's passenger chat: loads the REST history, then attaches to
/// the `TripChatConsumer` socket for live messages.
///
/// Lifecycle: [open] loads history and connects the socket; [close] tears the
/// consumer down. Sends are optimistically queued only while connected — the
/// backend does NOT echo a driver's own outbound message back over the socket,
/// so a sent line is appended locally and marked with an [AppLogger] note (no
/// delivery receipt exists in the documented protocol).
class TripChatNotifier extends Notifier<TripChatState> {
  TripChatConsumer? _consumer;
  StreamSubscription<TripChatEvent>? _eventSub;
  StreamSubscription<WebSocketState>? _connSub;
  bool _disposed = false;

  @override
  TripChatState build() {
    // Pause/resume the chat socket's reconnect budget with platform
    // connectivity so airplane mode never exhausts the backoff while a chat is
    // open (docs/14_ERROR_HANDLING.md:18).
    ref.listen<bool>(isOnlineNetworkProvider, (previous, next) {
      if (previous == next) return;
      _consumer?.updateNetworkStatus(next);
    });
    ref.onDispose(() {
      _disposed = true;
      _teardown();
    });
    return const TripChatState();
  }

  /// Opens a chat for [tripId]: fetch REST history, then connect the socket.
  Future<void> open(int tripId) async {
    if (_consumer != null && _consumer!.tripId == tripId) return;

    _teardown();
    final repository = ref.read(supportRepositoryProvider);
    state = const TripChatState(connecting: true, isLoadingHistory: true);

    // History first so the room has context before live frames arrive.
    try {
      final history = await repository.getTripChatHistory(tripId.toString());
      if (_disposed) return;
      state = state.copyWith(
        messages: history,
        isLoadingHistory: false,
        errorMessage: null,
      );
    } catch (e) {
      AppLogger.w('Chat history load failed', e);
      if (_disposed) return;
      state = state.copyWith(
        isLoadingHistory: false,
        // Non-fatal: live socket can still start a fresh conversation.
        errorMessage: 'Could not load earlier messages.',
      );
    }

    _attachConsumer(tripId);
    _consumer!.connect();
  }

  void _attachConsumer(int tripId) {
    final consumer = ref.read(tripChatConsumerFactoryProvider)(tripId);
    _consumer = consumer;
    _eventSub = consumer.events.listen(_onEvent);
    _connSub = consumer.connectionState.listen(_onConnectionState);
  }

  void _onEvent(TripChatEvent event) {
    switch (event) {
      case TripChatConnectionEstablished():
        state = state.copyWith(connecting: false, socketError: false);
        // Ask the backend to mark this driver's view as read.
        _consumer?.markAllRead();

      case TripChatMessageReceived(:final message):
        // Guard against duplicate echo frames: dedupe by id when present.
        if (message.id > 0 &&
            state.messages.any((existing) => existing.id == message.id)) {
          return;
        }
        state = state.copyWith(
          messages: [...state.messages, message],
          errorMessage: null,
        );

      case TripChatErrorEvent(:final message):
        state = state.copyWith(sending: false, errorMessage: message);

      case TripChatUnknownEvent(:final type):
        AppLogger.w('Unhandled chat event type: $type');
    }
  }

  void _onConnectionState(WebSocketState wsState) {
    switch (wsState) {
      case WebSocketState.connecting:
      case WebSocketState.connected:
      case WebSocketState.disconnected:
        break;
      case WebSocketState.error:
        state = state.copyWith(
          socketError: true,
          connecting: false,
          errorMessage: 'Lost connection to chat. Reopen to reconnect.',
        );
    }
  }

  /// Sends a line over the socket and optimistically appends it (no echo).
  Future<void> send(String body) async {
    final consumer = _consumer;
    final text = body.trim();
    if (consumer == null || text.isEmpty) {
      if (consumer == null) {
        state = state.copyWith(
          errorMessage: 'Chat is not connected yet. Try again.',
        );
      }
      return;
    }
    state = state.copyWith(sending: true, errorMessage: null);
    consumer.sendMessage(text);
    // The documented protocol does not echo the sender's own message, so add
    // it locally for a responsive UI.
    final optimistic = ChatMessageModel(
      id: 0,
      senderRole: 'driver',
      body: text,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    state = state.copyWith(
      sending: false,
      messages: [...state.messages, optimistic],
    );
  }

  void acknowledgeError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Closes the chat (navigating away, trip settled).
  void close() {
    _teardown();
  }

  void _teardown() {
    _eventSub?.cancel();
    _eventSub = null;
    _connSub?.cancel();
    _connSub = null;
    final consumer = _consumer;
    _consumer = null;
    if (consumer != null) {
      consumer.disconnect();
      unawaited(consumer.dispose());
    }
  }
}
