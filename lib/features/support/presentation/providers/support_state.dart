import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/support_ticket_model.dart';

part 'support_state.freezed.dart';

/// State of the driver's support ticket list & creation flow
/// (Help & Support screen).
@freezed
abstract class SupportTicketsState with _$SupportTicketsState {
  const SupportTicketsState._();

  const factory SupportTicketsState({
    @Default([]) List<SupportTicketModel> tickets,

    /// First load in flight (full-screen spinner).
    @Default(false) bool isLoading,

    /// Pull-to-refresh in flight.
    @Default(false) bool isRefreshing,

    /// Creating an incident/ticket in flight.
    @Default(false) bool isSubmitting,

    String? errorMessage,

    /// Set when [submitTicket] succeeds so the UI can navigate to the detail.
    int? createdTicketId,
  }) = _SupportTicketsState;

  bool get isEmpty => tickets.isEmpty && !isLoading && errorMessage == null;
}

/// State of a single support ticket thread (detail screen).
@freezed
abstract class SupportTicketDetailState with _$SupportTicketDetailState {
  const SupportTicketDetailState._();

  const factory SupportTicketDetailState({
    SupportTicketModel? ticket,

    /// First load in flight.
    @Default(false) bool isLoading,

    /// Replying to the thread in flight.
    @Default(false) bool isSendingReply,

    /// Closing the ticket in flight.
    @Default(false) bool isClosing,

    String? errorMessage,
  }) = _SupportTicketDetailState;
}

/// State of the SOS trigger and emergency-contact flows (Safety Center).
@freezed
abstract class SosState with _$SosState {
  const SosState._();

  const factory SosState({
    /// Raising the SOS alert in flight.
    @Default(false) bool isRaising,

    /// The last successful alert, shown as a confirmation.
    String? confirmationMessage,

    /// Saving the emergency contact in flight.
    @Default(false) bool isSavingContact,

    String? errorMessage,

    /// Success feedback after saving the emergency contact.
    String? contactSavedMessage,
  }) = _SosState;
}
