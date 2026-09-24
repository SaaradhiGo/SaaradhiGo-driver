import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'ws_client.dart';

/// Sends a lifecycle command and waits for the server to say it committed.
///
/// Why this exists
/// ---------------
/// `WebSocket.send()` succeeding proves that bytes left this device. It does not
/// prove the server received the command, and it certainly does not prove anything
/// was written. A resolved pilot blocker turned on exactly that: the socket had
/// already been closed, `send()` succeeded anyway, and the app told the driver the
/// ride was finished while the trip stayed `in_progress`.
///
/// Before this, [TripController] sent a frame, set `isBusy`, and waited for the
/// `trip_status_update` **broadcast** — with no timeout and no retry. That
/// broadcast travels over the server's channel layer, which silently drops
/// messages to a busy channel, so the acknowledgement could be thrown away for a
/// command that did commit and the driver would wait forever.
///
/// The contract
/// ------------
/// The server now answers every command directly with `command_ack`, echoing the
/// `command_id` we chose:
///
/// ```
/// {"type":"command_ack","command":"complete","command_id":"<ours>",
///  "status":"committed|already_done|rejected","trip_status":"completed",
///  "reason":"<code>"}
/// ```
///
/// `committed` and `already_done` are both **success**. `already_done` means a
/// previous attempt of this same command already landed — which is precisely what
/// a retry after a lost acknowledgement should be told, and why retrying is safe.
///
/// Retry rules
/// -----------
///   * the same logical command keeps the SAME `command_id` across every attempt,
///     so the server can recognise it rather than treating each as new work;
///   * `rejected` is terminal — retrying an authorisation failure or an invalid
///     transition would loop forever against an answer that will not change;
///   * bounded attempts with backoff, never an unbounded loop, so a server having
///     a bad minute does not receive a retry storm from every driver at once;
///   * if the socket is down we wait for it to come back rather than firing into
///     a dead connection, because that is the failure this class exists to stop.
enum CommandOutcome {
  /// The server confirmed a durable write. Includes `already_done`.
  committed,

  /// The server refused. Terminal: do not retry.
  rejected,

  /// No acknowledgement after every attempt. The command may or may not have
  /// landed, so the caller must reconcile against durable state rather than
  /// guess — never present this as either success or failure.
  unknown,
}

@immutable
class CommandResult {
  const CommandResult({
    required this.outcome,
    required this.commandId,
    this.tripStatus,
    this.reason,
    this.detail,
    this.attempts = 1,
    this.wasAlreadyDone = false,
    this.viaBroadcast = false,
  });

  final CommandOutcome outcome;
  final String commandId;

  /// The durable trip status the server reported, e.g. `completed`. This is the
  /// stored value, not the verb we sent, so it can be compared with the API.
  final String? tripStatus;

  /// Stable machine-readable code on a rejection, e.g. `invalid_otp`.
  final String? reason;
  final String? detail;
  final int attempts;

  /// True when the server said the command had already taken effect. Useful for
  /// telemetry: a non-zero rate here means acknowledgements are being lost.
  final bool wasAlreadyDone;

  /// True when this was resolved by the legacy `trip_status_update` broadcast
  /// rather than a `command_ack`. Expected only against a server that predates
  /// the ack protocol; a non-zero rate in production means a version skew.
  final bool viaBroadcast;

  bool get isSuccess => outcome == CommandOutcome.committed;
}

class CommandDispatcher {
  CommandDispatcher({
    required this.socket,
    this.ackTimeout = const Duration(seconds: 8),
    this.maxAttempts = 4,
    this.reconnectGrace = const Duration(seconds: 12),
    String Function()? idFactory,
    math.Random? random,
  })  : _idFactory = idFactory ?? _defaultId,
        _random = random ?? math.Random();

  final WsClient socket;

  /// How long to wait for `command_ack` before trying again. Generous, because a
  /// premature retry is worse than a slow one.
  final Duration ackTimeout;

  /// Total attempts, not additional ones. Bounded on purpose.
  final int maxAttempts;

  /// How long to let the socket come back before giving up on an attempt.
  final Duration reconnectGrace;

  final String Function() _idFactory;
  final math.Random _random;

  static int _counter = 0;

  static String _defaultId() {
    // Good enough for correlation: unique per device per command, and the server
    // treats it as opaque. Deliberately not a package dependency for this.
    _counter += 1;
    final now = DateTime.now().microsecondsSinceEpoch;
    final salt = math.Random().nextInt(0xFFFFFF).toRadixString(16);
    return '$now-$_counter-$salt';
  }

  /// Send [action], retrying the same command until the server answers.
  ///
  /// [commandId] may be supplied to resume a command whose acknowledgement was
  /// lost across an app restart; otherwise one is generated.
  Future<CommandResult> send(
    String action, {
    Map<String, dynamic>? extra,
    String? commandId,
  }) async {
    final id = commandId ?? _idFactory();

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (!await _awaitConnection()) {
        // No socket at all. Nothing was sent, so a later attempt is safe.
        if (attempt == maxAttempts) {
          return CommandResult(
            outcome: CommandOutcome.unknown,
            commandId: id,
            reason: 'not_connected',
            attempts: attempt,
          );
        }
        await _backoff(attempt);
        continue;
      }

      // Subscribe BEFORE sending, or a fast server can answer into the gap.
      final ack = _awaitAnswer(id, action);
      socket.send({'action': action, 'command_id': id, ...?extra});

      final frame = await ack;
      if (frame == null) {
        if (attempt == maxAttempts) {
          return CommandResult(
            outcome: CommandOutcome.unknown,
            commandId: id,
            reason: 'ack_timeout',
            attempts: attempt,
          );
        }
        await _backoff(attempt);
        continue;
      }

      if (frame['type'] != 'command_ack') {
        // A server without ack support. The broadcast (or its `error`) is the only
        // answer available, so use it rather than hanging: this app must keep
        // working if the server is older than it, or gets rolled back.
        final isError = frame['type'] == 'error';
        return CommandResult(
          outcome:
              isError ? CommandOutcome.rejected : CommandOutcome.committed,
          commandId: id,
          // The broadcast carries the verb ('complete'), not the stored status;
          // TripStatus.parse accepts both.
          tripStatus: frame['status']?.toString(),
          detail: isError ? frame['message']?.toString() : null,
          attempts: attempt,
          viaBroadcast: true,
        );
      }

      final status = frame['status']?.toString();
      final tripStatus = frame['trip_status']?.toString();

      if (status == 'committed' || status == 'already_done') {
        return CommandResult(
          outcome: CommandOutcome.committed,
          commandId: id,
          tripStatus: tripStatus,
          attempts: attempt,
          wasAlreadyDone: status == 'already_done',
        );
      }

      // `rejected` is an answer, not a failure to deliver. Retrying it would
      // loop against a decision that will not change.
      return CommandResult(
        outcome: CommandOutcome.rejected,
        commandId: id,
        tripStatus: tripStatus,
        reason: frame['reason']?.toString(),
        detail: frame['detail']?.toString() ?? frame['message']?.toString(),
        attempts: attempt,
      );
    }

    return CommandResult(
      outcome: CommandOutcome.unknown,
      commandId: id,
      reason: 'exhausted',
      attempts: maxAttempts,
    );
  }

  /// The server's answer to this command, or null if [ackTimeout] passes first.
  ///
  /// Prefers a correlated `command_ack`. Falls back to the older, uncorrelated
  /// signals -- the `trip_status_update` broadcast and the `error` frame -- so
  /// this app still works against a server that predates the ack protocol, or one
  /// that has been rolled back. Without that fallback, a version skew would leave
  /// every lifecycle command hanging, which is a worse failure than the one this
  /// class was written to fix.
  Future<Map<String, dynamic>?> _awaitAnswer(String id, String action) {
    return socket.events
        .where((e) => _isAckFor(e, id) || _isLegacyAnswerFor(e, action))
        .cast<Map<String, dynamic>?>()
        .first
        .timeout(ackTimeout, onTimeout: () => null);
  }

  bool _isAckFor(Map<String, dynamic> e, String id) =>
      e['type'] == 'command_ack' && e['command_id']?.toString() == id;

  /// The pre-ack contract: a status broadcast naming this action, or an `error`.
  ///
  /// `error` is uncorrelated, so in principle it could belong to something else.
  /// In practice the UI issues one command at a time on a per-trip socket, and
  /// this is exactly how the controller behaved before the ack protocol existed,
  /// so it is not a new risk.
  bool _isLegacyAnswerFor(Map<String, dynamic> e, String action) {
    final type = e['type'];
    if (type == 'error') return true;
    // `confirm_cash` has never been answered by a status broadcast; its reply is
    // its own frame type.
    if (type == 'cash_payment_confirmed') return action == 'confirm_cash';
    if (type != 'trip_status_update' && type != 'trip_update') return false;
    return e['status']?.toString() == action;
  }

  /// True once connected, waiting up to [reconnectGrace]. [WsClient] reconnects
  /// on its own; this only declines to shout into a closed socket.
  Future<bool> _awaitConnection() async {
    if (socket.isConnected) return true;
    try {
      await socket.status
          .firstWhere((s) => s == WsStatus.connected)
          .timeout(reconnectGrace);
      return true;
    } on Object {
      return socket.isConnected;
    }
  }

  /// Exponential with jitter. The jitter matters: without it every driver whose
  /// command timed out retries in the same instant.
  Future<void> _backoff(int attempt) {
    final base = 400 * math.pow(2, attempt - 1).toInt();
    final jitter = _random.nextInt(250);
    final capped = math.min(base + jitter, 6000);
    return Future<void>.delayed(Duration(milliseconds: capped));
  }
}
