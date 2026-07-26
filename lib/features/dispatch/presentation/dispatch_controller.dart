import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../duty/presentation/duty_controller.dart';
import '../domain/ride_offer.dart';

/// Why an offer left the screen. Kept because "it vanished" is the single
/// most common driver complaint about dispatch in this category of app, and
/// each of these deserves a different message.
enum OfferOutcome { accepted, rejected, expired, takenByAnother, failed }

@immutable
class DispatchState {
  const DispatchState({
    this.offer,
    this.isResponding = false,
    this.lastOutcome,
    this.error,
  });

  /// At most one offer on screen at a time. The server's rolling fanout can
  /// legitimately offer two trips to the same driver seconds apart; showing
  /// both would have a driver accepting a ride while a second card covers
  /// the screen.
  final RideOffer? offer;

  final bool isResponding;
  final OfferOutcome? lastOutcome;
  final Object? error;

  bool get hasOffer => offer != null;

  DispatchState copyWith({
    RideOffer? offer,
    bool? isResponding,
    OfferOutcome? lastOutcome,
    Object? error,
    bool clearOffer = false,
    bool clearError = false,
  }) =>
      DispatchState(
        offer: clearOffer ? null : (offer ?? this.offer),
        isResponding: isResponding ?? this.isResponding,
        lastOutcome: lastOutcome ?? this.lastOutcome,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Presents incoming offers and records the driver's answer.
///
/// The accept itself goes over the per-trip socket (see TripController) —
/// this controller owns which offer is on screen, its countdown, and the
/// pile of ways an offer can disappear.
class DispatchController extends Notifier<DispatchState> {
  StreamSubscription<RideOffer>? _offerSub;
  StreamSubscription<int>? _takenSub;
  Timer? _ticker;

  @override
  DispatchState build() {
    final duty = ref.watch(dutyControllerProvider.notifier);

    _offerSub = duty.offers.listen(_onOffer);
    _takenSub = duty.tripTaken.listen(_onTaken);

    ref.onDispose(() {
      _offerSub?.cancel();
      _takenSub?.cancel();
      _ticker?.cancel();
    });

    return const DispatchState();
  }

  void _onOffer(RideOffer offer) {
    // Ignore a duplicate re-offer of the trip already on screen (the server
    // can re-broadcast on a later wave), but let a genuinely new trip replace
    // a stale card.
    if (state.offer?.tripId == offer.tripId) return;
    state = state.copyWith(offer: offer, clearError: true);
    _startTicker();
  }

  void _onTaken(int tripId) {
    if (state.offer?.tripId != tripId) return;
    _dismiss(OfferOutcome.takenByAnother);
  }

  void _startTicker() {
    _ticker?.cancel();
    // Drives the countdown ring. 200ms is smooth enough to read as a timer
    // without waking the UI thread 60 times a second.
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final offer = state.offer;
      if (offer == null) {
        _ticker?.cancel();
        return;
      }
      if (offer.isExpired) {
        _dismiss(OfferOutcome.expired);
        return;
      }
      // Rebuild for the countdown. State is immutable, so hand out a new
      // instance carrying the same offer.
      state = state.copyWith();
    });
  }

  void _dismiss(OfferOutcome outcome) {
    _ticker?.cancel();
    _ticker = null;
    state = DispatchState(lastOutcome: outcome);
  }

  /// Called by the trip controller once the accept round-trip resolves.
  void markAccepted() => _dismiss(OfferOutcome.accepted);

  void markFailed(Object error) {
    _ticker?.cancel();
    state = DispatchState(lastOutcome: OfferOutcome.failed, error: error);
  }

  /// Driver tapped Reject.
  ///
  /// Deliberately local: the backend has no reject endpoint, and rejecting is
  /// not the same as cancelling. Dropping the card leaves the trip live for
  /// the other drivers in the wave, which is exactly the intended behaviour.
  void reject() => _dismiss(OfferOutcome.rejected);

  void setResponding(bool value) =>
      state = state.copyWith(isResponding: value);

  void clearOutcome() => state = const DispatchState();
}

final dispatchControllerProvider =
    NotifierProvider<DispatchController, DispatchState>(
  DispatchController.new,
);
