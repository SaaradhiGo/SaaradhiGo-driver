import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/chat_message_model.dart';

part 'trip_chat_state.freezed.dart';

/// Live state of one trip's passenger chat session.
///
/// Mirrors the transport/lifecycle vocabulary used by [TripSessionState]
/// (connecting / socketError) so screens can render the same 8 UI states.
@freezed
abstract class TripChatState with _$TripChatState {
  const TripChatState._();

  const factory TripChatState({
    @Default([]) List<ChatMessageModel> messages,

    /// Socket opening in flight, before `connection_established`.
    @Default(false) bool connecting,

    /// Chat history REST load in flight.
    @Default(false) bool isLoadingHistory,

    /// The transport exhausted its reconnect budget.
    @Default(false) bool socketError,

    /// Outbound send in flight (the backend does not echo driver sends).
    @Default(false) bool sending,

    /// Recoverable banner/snackbar error (e.g. `{type:error}` frame).
    String? errorMessage,
  }) = _TripChatState;

  /// True while the chat has no lines to display and isn't busy.
  bool get isEmpty =>
      messages.isEmpty &&
      !connecting &&
      !isLoadingHistory &&
      errorMessage == null;
}
