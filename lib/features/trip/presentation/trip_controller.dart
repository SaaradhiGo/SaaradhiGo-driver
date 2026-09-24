import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/ws/command_dispatcher.dart';
import '../../../core/ws/ws_client.dart';
import '../../dispatch/presentation/dispatch_controller.dart';
import '../domain/trip.dart';

@immutable
class TripState {
  const TripState({
    this.trip,
    this.isBusy = false,
    this.error,
    this.otpError,
    this.connection = WsStatus.idle,
    this.justCompleted = false,
  });

  final Trip? trip;
  final bool isBusy;
  final Object? error;

  /// Separate from [error] because a wrong OTP is a normal thing that happens
  /// at a kerbside, not a failure banner.
  final String? otpError;

  final WsStatus connection;

  /// Set for one frame after completion so the UI can route to the payment
  /// summary exactly once.
  final bool justCompleted;

  bool get hasTrip => trip != null;

  TripState copyWith({
    Trip? trip,
    bool? isBusy,
    Object? error,
    String? otpError,
    WsStatus? connection,
    bool? justCompleted,
    bool clearTrip = false,
    bool clearError = false,
    bool clearOtpError = false,
  }) =>
      TripState(
        trip: clearTrip ? null : (trip ?? this.trip),
        isBusy: isBusy ?? this.isBusy,
        error: clearError ? null : (error ?? this.error),
        otpError: clearOtpError ? null : (otpError ?? this.otpError),
        connection: connection ?? this.connection,
        justCompleted: justCompleted ?? this.justCompleted,
      );
}

/// Owns the active trip and the socket that drives it.
///
/// Mirrors the server's `TripStatusConsumer` contract exactly:
///   accept → reached → start (with the rider's OTP) → complete
/// plus `confirm_cash` and `cancel`. Every action is a WS frame; the server
/// enforces the transitions and the authorisation, and we render what it
/// says rather than assuming success.
class TripController extends Notifier<TripState> {
  WsClient? _socket;

  /// Waits for the server's `command_ack` instead of trusting `send()`.
  /// Created with the socket, discarded with it.
  CommandDispatcher? _commands;

  /// Which trip [_socket] is currently attached to, so adopting a trip we
  /// just accepted does not tear down the very socket that carried the
  /// acceptance — a needless disconnect with a window where trip events
  /// could be missed.
  int? _socketTripId;

  StreamSubscription<Map<String, dynamic>>? _eventSub;
  StreamSubscription<WsStatus>? _statusSub;
  Completer<bool>? _pendingAccept;

  @override
  TripState build() {
    ref.onDispose(_teardown);
    return const TripState();
  }

  /// Cold start: local snapshot for an instant paint, then the server decides.
  ///
  /// The snapshot is a cache and can be wrong (the trip may have been
  /// cancelled while the app was dead), so a null answer from `/ride/active/`
  /// clears it rather than being treated as "no data, keep showing".
  Future<void> restore() async {
    final store = ref.read(localStoreProvider);
    final cached = store.readTripSnapshot();
    if (cached != null) {
      state = state.copyWith(trip: Trip.fromJson(cached));
    }

    try {
      final live = await ref.read(tripRepositoryProvider).fetchActiveTrip();
      if (live == null) {
        await store.writeTripSnapshot(null);
        state = const TripState();
        return;
      }
      await _adopt(live);
    } on Object catch (e) {
      // Offline on launch: keep the cached trip on screen rather than
      // showing a driver mid-ride an empty home.
      debugPrint('TripController.restore: $e');
      state = state.copyWith(error: e);
    }
  }

  /// Take ownership of a trip and open its socket.
  Future<void> _adopt(Trip trip) async {
    state = state.copyWith(trip: trip, clearError: true);
    await ref.read(localStoreProvider).writeTripSnapshot(trip.toJson());
    await _openSocket(trip.id);
  }

  /// Accept an offer.
  ///
  /// The socket connects, we send `{"action":"accept"}`, and the server
  /// answers with either a `trip_status_update` (we won) or `trip_taken`
  /// (someone else did, and it closes the socket on us).
  Future<bool> acceptOffer(int tripId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    final completer = Completer<bool>();
    _pendingAccept = completer;

    try {
      await _openSocket(tripId);
      _socket?.send({'action': 'accept'});

      // Bounded wait: if the server never answers we must not leave the
      // driver staring at a spinner while the offer expires.
      final won = await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => false,
      );

      if (won) {
        final trip = await ref.read(tripRepositoryProvider).fetchTrip(tripId);
        await _adopt(trip);
        ref.read(dispatchControllerProvider.notifier).markAccepted();
      } else {
        await _closeSocket();
      }
      state = state.copyWith(isBusy: false);
      return won;
    } on Object catch (e) {
      await _closeSocket();
      state = state.copyWith(isBusy: false, error: e);
      return false;
    } finally {
      _pendingAccept = null;
    }
  }

  Future<void> markArrived() => _send('reached');

  /// Start the ride. The rider reads the OTP aloud; the server compares it
  /// and refuses on mismatch, with a 5-attempt lockout per trip.
  Future<void> startTrip(String otp) async {
    state = state.copyWith(clearOtpError: true);
    await _send('start', extra: {'otp': otp});
  }

  Future<void> completeTrip() => _send('complete');

  /// Cash collected. The server gates this on the trip being completed and
  /// is idempotent, so a double-tap is harmless.
  Future<void> confirmCash() => _send('confirm_cash');

  /// Driver cancels before the ride starts. Goes over REST rather than the
  /// socket because that endpoint applies the penalty ledger and the rolling
  /// cancellation cooldown.
  Future<bool> cancelTrip({required String reason, String? note}) async {
    final trip = state.trip;
    if (trip == null) return false;

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await ref.read(tripRepositoryProvider).cancelTrip(
            tripId: trip.id,
            reason: reason,
            note: note,
          );
      await clearTrip();
      return true;
    } on Object catch (e) {
      state = state.copyWith(isBusy: false, error: e);
      return false;
    }
  }

  /// Issue a lifecycle command and wait for the server to confirm it committed.
  ///
  /// This used to be `socket.send(...)` followed by an open-ended wait for the
  /// `trip_status_update` broadcast. Two things were wrong with that, and the
  /// second is the reason a driver was once shown a finished ride whose trip was
  /// still `in_progress`:
  ///
  ///   * `send()` succeeding proves only that bytes left this device. On a
  ///     half-open socket it succeeds and the command is simply lost.
  ///   * the broadcast is delivered over the server's channel layer, which
  ///     silently drops messages to a busy channel. The acknowledgement for a
  ///     command that *did* commit could be thrown away, and with no timeout we
  ///     would sit in `isBusy` forever.
  ///
  /// Now we wait for a correlated `command_ack`, retry the same `command_id` on
  /// silence, and — crucially — never claim success without one. An
  /// unacknowledged command reconciles against durable state instead of guessing.
  Future<void> _send(String action, {Map<String, dynamic>? extra}) async {
    final dispatcher = _commands;
    if (dispatcher == null) {
      state = state.copyWith(
        error: Exception('Not connected. Reconnecting — try again shortly.'),
      );
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    final result = await dispatcher.send(action, extra: extra);

    switch (result.outcome) {
      case CommandOutcome.committed:
        // `already_done` lands here too, and must: it means a previous attempt of
        // this same command committed. Treating it as an error would show a
        // failure on a ride that had finished.
        _applyStatus(result.tripStatus);
        if (result.wasAlreadyDone) {
          debugPrint(
            'command $action was already applied server-side '
            '(attempts=${result.attempts}) — an ack was lost',
          );
        }

      case CommandOutcome.rejected:
        final message = result.detail ?? 'Action failed';
        final isOtp = (result.reason ?? '').contains('otp') ||
            message.toLowerCase().contains('otp');
        state = state.copyWith(
          isBusy: false,
          otpError: isOtp ? message : null,
          error: isOtp ? null : Exception(message),
        );
        // A rejection still tells us the durable state, so stop guessing.
        _applyStatus(result.tripStatus, clearBusy: false);

      case CommandOutcome.unknown:
        // The honest case. We do not know whether it landed, so we neither claim
        // success nor claim failure: we re-read the trip from the server, which
        // is durable truth, and let that decide.
        debugPrint(
          'command $action unacknowledged after ${result.attempts} attempts '
          '(${result.reason}) — reconciling against the server',
        );
        await _reconcile();
    }
  }

  /// Fold a server-reported durable status into local state.
  ///
  /// Takes the stored value (`completed`), not the verb we sent (`complete`).
  void _applyStatus(String? statusCode, {bool clearBusy = true}) {
    if (statusCode == null) {
      if (clearBusy) state = state.copyWith(isBusy: false);
      return;
    }
    final status = TripStatus.parse(statusCode);
    final current = state.trip;
    if (current == null) {
      if (clearBusy) state = state.copyWith(isBusy: false);
      return;
    }

    final updated = current.copyWith(
      status: status,
      reachedAt: status == TripStatus.reached ? DateTime.now() : null,
      startedAt: status == TripStatus.inProgress ? DateTime.now() : null,
      completedAt: status == TripStatus.completed ? DateTime.now() : null,
      cancelledAt: status == TripStatus.cancelled ? DateTime.now() : null,
      otpVerified: status == TripStatus.inProgress ? true : null,
    );

    state = state.copyWith(
      trip: updated,
      isBusy: clearBusy ? false : null,
      clearError: true,
      clearOtpError: true,
      justCompleted: status == TripStatus.completed,
    );
    unawaited(
      ref.read(localStoreProvider).writeTripSnapshot(updated.toJson()),
    );
  }

  /// Ask the server what is actually true.
  ///
  /// Used when a command went unacknowledged. PostgreSQL wins over anything this
  /// app believes, so a completion that committed is discovered rather than
  /// retried, and one that did not is left retryable.
  Future<void> _reconcile() async {
    try {
      final trip = await ref.read(tripRepositoryProvider).fetchActiveTrip();
      if (trip == null) {
        // No active trip means it reached a terminal state. Do not invent which.
        state = state.copyWith(isBusy: false);
        return;
      }
      state = state.copyWith(
        trip: trip,
        isBusy: false,
        clearError: true,
        justCompleted: trip.status == TripStatus.completed,
      );
      unawaited(
        ref.read(localStoreProvider).writeTripSnapshot(trip.toJson()),
      );
    } on Object catch (e) {
      state = state.copyWith(
        isBusy: false,
        error: Exception(
          'Could not confirm the last action. Check your connection and '
          'refresh before retrying.',
        ),
      );
      debugPrint('reconcile failed: $e');
    }
  }

  Future<void> _openSocket(int tripId) async {
    if (_socketTripId == tripId && (_socket?.isConnected ?? false)) return;
    await _closeSocket();

    final tokenStore = ref.read(tokenStoreProvider);
    final socket = WsClient(
      connector: ref.read(wsConnectorProvider),
      tokenProvider: tokenStore.readAccess,
      path: () async {
        final token = await tokenStore.readAccess() ?? '';
        return ApiEndpoints.tripSocket(tripId: tripId, token: token);
      },
    );
    _socket = socket;
    _commands = CommandDispatcher(socket: socket);
    _socketTripId = tripId;
    _eventSub = socket.events.listen(_onEvent);
    _statusSub = socket.status.listen((ws) {
      state = state.copyWith(connection: ws);
    });
    await socket.connect();
  }

  void _onEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString();

    switch (type) {
      case 'trip_taken':
        _pendingAccept?.complete(false);
        _pendingAccept = null;
        ref.read(dispatchControllerProvider.notifier).clearOutcome();

      case 'trip_status_update':
      case 'trip_update':
        final status = TripStatus.parse(event['status']);
        _pendingAccept?.complete(status != TripStatus.requested);
        _pendingAccept = null;

        final current = state.trip;
        if (current == null) return;

        final updated = current.copyWith(
          status: status,
          reachedAt: status == TripStatus.reached ? DateTime.now() : null,
          startedAt: status == TripStatus.inProgress ? DateTime.now() : null,
          completedAt: status == TripStatus.completed ? DateTime.now() : null,
          cancelledAt: status == TripStatus.cancelled ? DateTime.now() : null,
          otpVerified: status == TripStatus.inProgress ? true : null,
        );

        state = state.copyWith(
          trip: updated,
          isBusy: false,
          clearError: true,
          clearOtpError: true,
          justCompleted: status == TripStatus.completed,
        );
        unawaited(
          ref.read(localStoreProvider).writeTripSnapshot(updated.toJson()),
        );

      case 'cash_payment_confirmed':
        final current = state.trip;
        if (current == null) return;
        state = state.copyWith(
          trip: current.copyWith(paymentStatus: 'completed'),
          isBusy: false,
        );

      case 'error':
        final message = event['message']?.toString() ?? 'Action failed';
        // The OTP path has its own inline surface; everything else is a
        // banner. Both come back on the same frame type, so we branch on
        // the server's wording.
        final isOtp = message.toLowerCase().contains('otp');
        state = state.copyWith(
          isBusy: false,
          otpError: isOtp ? message : null,
          error: isOtp ? null : Exception(message),
        );
        if (_pendingAccept != null) {
          _pendingAccept?.complete(false);
          _pendingAccept = null;
        }
    }
  }

  /// Drop the finished trip and go back to waiting for offers.
  Future<void> clearTrip() async {
    await _closeSocket();
    await ref.read(localStoreProvider).writeTripSnapshot(null);
    state = const TripState();
  }

  void acknowledgeCompletion() =>
      state = state.copyWith(justCompleted: false);

  Future<void> _closeSocket() async {
    _socketTripId = null;
    _commands = null;
    await _eventSub?.cancel();
    _eventSub = null;
    await _statusSub?.cancel();
    _statusSub = null;
    await _socket?.dispose();
    _socket = null;
  }

  void _teardown() {
    _eventSub?.cancel();
    _statusSub?.cancel();
    _socket?.dispose();
  }
}

final tripControllerProvider =
    NotifierProvider<TripController, TripState>(TripController.new);
