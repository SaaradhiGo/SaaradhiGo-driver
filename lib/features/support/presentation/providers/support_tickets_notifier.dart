import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/repositories/support_repository.dart';
import 'support_providers.dart';

/// Drives the Help & Support ticket list and the Report Incident creation
/// flow. Tickets are fetched once on screen entry ([loadTickets]) and again on
/// pull-to-refresh ([refresh]); [submitTicket] creates a new ticket from an
/// incident report and stores its id in [SupportTicketsState.createdTicketId]
/// so the screen can navigate into the freshly created thread.
class SupportTicketsNotifier extends Notifier<SupportTicketsState> {
  late SupportRepository _repository;

  @override
  SupportTicketsState build() {
    _repository = ref.watch(supportRepositoryProvider);
    return const SupportTicketsState();
  }

  bool get _isBusy =>
      state.isLoading || state.isRefreshing || state.isSubmitting;

  /// First load of the ticket list (full-screen spinner).
  Future<void> loadTickets() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tickets = await _repository.listTickets();
      state = state.copyWith(isLoading: false, tickets: tickets);
    } catch (e) {
      AppLogger.w('Support ticket list load failed', e);
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Could not load your tickets. Check your connection and '
            'try again.',
      );
    }
  }

  /// Pull-to-refresh; keeps the existing list visible on failure.
  Future<void> refresh() async {
    if (_isBusy) return;
    state = state.copyWith(isRefreshing: true, errorMessage: null);
    try {
      final tickets = await _repository.listTickets();
      state = state.copyWith(isRefreshing: false, tickets: tickets);
    } catch (e) {
      AppLogger.w('Support ticket list refresh failed', e);
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: 'Could not refresh your tickets. Try again.',
      );
    }
  }

  /// Creates a support ticket (Report an Incident). On success the returned
  /// ticket is prepended to the list so it appears immediately, and its id is
  /// exposed on [SupportTicketsState.createdTicketId].
  Future<void> submitTicket({
    required String category,
    required String subject,
    required String description,
    int? tripId,
  }) async {
    if (state.isSubmitting) return;
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      createdTicketId: null,
    );
    try {
      final ticket = await _repository.createTicket(
        category: category,
        subject: subject,
        description: description,
        tripId: tripId,
      );
      state = state.copyWith(
        isSubmitting: false,
        tickets: [ticket, ...state.tickets],
        createdTicketId: ticket.id,
      );
    } catch (e) {
      AppLogger.w('Support ticket create failed', e);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            'Could not submit your report. Check your connection and '
            'try again.',
      );
    }
  }

  /// Clears the navigation marker after the screen has consumed it.
  void clearCreatedTicket() {
    if (state.createdTicketId == null) return;
    state = state.copyWith(createdTicketId: null);
  }

  void acknowledgeError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }
}
