import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/support_message_model.dart';
import '../../domain/repositories/support_repository.dart';
import 'support_providers.dart';

/// Drives a single support ticket thread (Support Ticket Detail screen).
/// [open] fetches the full thread; [sendReply] posts a new driver message and
/// appends it locally; [closeTicket] resolves/ends the thread. The screen
/// passes its route ticket id via [open] — a single Notifier is reused because
/// the feature screens are opened one at a time and there is no multi-thread
/// UI in the driver app.
class SupportTicketDetailNotifier extends Notifier<SupportTicketDetailState> {
  late SupportRepository _repository;
  int? _ticketId;

  @override
  SupportTicketDetailState build() {
    _repository = ref.watch(supportRepositoryProvider);
    ref.onDispose(() => _ticketId = null);
    return const SupportTicketDetailState();
  }

  /// Loads the thread for [ticketId]. Re-loading a different ticket replaces
  /// the current state.
  Future<void> open(int ticketId) async {
    _ticketId = ticketId;
    if (state.isLoading) return;
    state = const SupportTicketDetailState(isLoading: true);
    try {
      final ticket = await _repository.getTicketDetail(ticketId);
      if (_ticketId != ticketId) return; // Stale: a newer open() replaced us.
      state = SupportTicketDetailState(ticket: ticket);
    } catch (e) {
      AppLogger.w('Support ticket detail load failed', e);
      if (_ticketId != ticketId) return;
      state = SupportTicketDetailState(
        errorMessage: 'Could not load this ticket. Try again.',
      );
    }
  }

  /// Posts a driver reply. The API contract (8.4) documents no response body,
  /// so on success the optimistic line is kept in the thread and the ticket is
  /// refreshed to pick up any server-generated fields (status transitions etc.)
  /// without blocking the UI on a second round trip.
  Future<void> sendReply(String body) async {
    final ticketId = _ticketId;
    final text = body.trim();
    if (ticketId == null || text.isEmpty) return;
    if (state.isSendingReply || state.isClosing) return;

    final currentTicket = state.ticket;
    if (currentTicket == null) return;

    state = state.copyWith(isSendingReply: true, errorMessage: null);

    // Optimistic echo for a responsive thread; no server echo is documented.
    final optimistic = SupportMessageModel(
      senderRole: 'driver',
      body: text,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    state = state.copyWith(
      isSendingReply: false,
      ticket: currentTicket.copyWith(
        messages: [...currentTicket.messages, optimistic],
      ),
    );

    try {
      await _repository.addTicketMessage(ticketId, text);
      // Refresh after the post succeeds so server timestamps / status appear.
      await _reloadSilently(ticketId);
    } catch (e) {
      AppLogger.w('Support reply send failed', e);
      state = state.copyWith(
        errorMessage: 'Your reply could not be sent. Try again.',
      );
    }
  }

  /// Closes the ticket (8.5).
  Future<void> closeTicket() async {
    final ticketId = _ticketId;
    if (ticketId == null) return;
    if (state.isClosing || state.isSendingReply) return;

    state = state.copyWith(isClosing: true, errorMessage: null);
    try {
      final updated = await _repository.closeTicket(ticketId);
      state = SupportTicketDetailState(ticket: updated);
    } catch (e) {
      AppLogger.w('Support ticket close failed', e);
      state = state.copyWith(
        isClosing: false,
        errorMessage: 'Could not close this ticket. Try again.',
      );
    }
  }

  Future<void> _reloadSilently(int ticketId) async {
    try {
      final ticket = await _repository.getTicketDetail(ticketId);
      if (_ticketId != ticketId) return;
      state = SupportTicketDetailState(ticket: ticket);
    } catch (e) {
      AppLogger.w('Support ticket silent refresh failed', e);
      // Keep the optimistic thread; the user can pull-to-refresh.
    }
  }

  void acknowledgeError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }
}
