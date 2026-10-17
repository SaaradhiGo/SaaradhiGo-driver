/// One place that decides whether a ride offer is shown to the driver.
///
/// TWO CHANNELS, ONE DRIVER
/// ------------------------
/// `servers/ride/dispatch.py` announces every offer twice: a `ride_request`
/// frame on the driver's dispatch WebSocket, and an FCM push to the same
/// driver. That is deliberate — the socket is only connected while the app is
/// running and reachable, and push is what reaches a backgrounded or
/// terminated app — but it means both can arrive for the same trip, and
/// without a single arbiter the driver gets the bottom sheet twice.
///
/// WHAT A PUSH CAN AND CANNOT DO
/// -----------------------------
/// The push carries `{trip_id, type}` and nothing else, and
/// `GET /ride/trip/<id>/` refuses a driver who is not yet **assigned** — only
/// the rider and the assigned driver may read a trip. So a push cannot
/// populate the offer sheet: there is no API that will tell an un-assigned
/// driver who the rider is or where they are.
///
/// Therefore a push does one job: bring the app forward and make sure the
/// dispatch socket is connected, so the socket's own `ride_request` frame can
/// supply the details. If no frame arrives within [socketGrace], the offer is
/// gone — a wave moved on, or the trip was taken or cancelled — and the
/// driver is told that rather than shown a sheet that cannot be accepted.
///
/// (Recorded as a backend gap: dispatch could put the offer fields in the
/// push `data`, or expose an offers endpoint. Either would let a tapped
/// notification present the ride immediately.)
///
/// STALENESS
/// ---------
/// The payload has no expiry field, and a push can be delivered late or
/// tapped hours later from the notification shade. The backend schedules
/// `auto_cancel_trip` with `TRIP_ACCEPT_TIMEOUT_SECONDS` (90s), after which
/// the trip is closed no matter what the driver does. An offer older than
/// that is dead on arrival, so it is dropped silently instead of waking a
/// driver for a ride nobody can give them.
library;

import 'dart:async';

import '../utils/app_logger.dart';
import 'push_offer.dart';
import 'push_transport.dart';

/// Why the coordinator did or did not act on an announcement.
enum OfferDecision {
  /// Shown to the driver.
  presented,

  /// A push arrived; the app is being brought forward and the socket asked
  /// for details.
  awaitingSocketDetails,

  /// Already presented or already accepted/declined this session.
  duplicate,

  /// Older than the backend's accept timeout.
  stale,

  /// The driver is already on a trip.
  busy,

  /// A push for a trip whose details never arrived.
  expired,
}

/// An offer that is ready to show, with the socket payload behind it.
class PresentableOffer {
  const PresentableOffer({
    required this.tripId,
    required this.payload,
    required this.cameFromPush,
  });

  final int tripId;

  /// The raw `ride_request` frame. The sheet reads this.
  final Map<String, dynamic> payload;

  /// True when a push announced this trip first, so the driver is expecting
  /// it and the app should move straight to the offer.
  final bool cameFromPush;
}

class RideOfferCoordinator {
  RideOfferCoordinator({
    required PushTransport transport,
    required bool Function() hasActiveTrip,
    this.offerLifetime = const Duration(seconds: 90),
    this.socketGrace = const Duration(seconds: 12),
    DateTime Function() now = DateTime.now,
  }) : _transport = transport,
       _hasActiveTrip = hasActiveTrip,
       _now = now;

  final PushTransport _transport;
  final bool Function() _hasActiveTrip;
  final DateTime Function() _now;

  /// Mirrors the backend's `TRIP_ACCEPT_TIMEOUT_SECONDS`.
  final Duration offerLifetime;

  /// How long to wait for the socket to supply details after a push.
  final Duration socketGrace;

  final _offers = StreamController<PresentableOffer>.broadcast();
  final _expired = StreamController<int>.broadcast();

  /// Trips already presented, accepted or declined this session.
  final Set<int> _settled = <int>{};

  /// Trips a push announced, waiting for the socket to describe them.
  final Map<int, Timer> _awaitingDetails = <int, Timer>{};

  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// Offers ready to show.
  Stream<PresentableOffer> get offers => _offers.stream;

  /// Trip ids announced by push whose details never arrived. The UI tells the
  /// driver the ride is no longer available.
  Stream<int> get expiredOffers => _expired.stream;

  /// For tests and logging: what the last announcement led to.
  OfferDecision? lastDecision;

  /// The offer presented most recently and not yet settled.
  ///
  /// Retained because the terminated-app path cannot be served by a stream
  /// alone: the launch notification is read in `main()`, before any screen
  /// exists, and the dashboard subscribes several frames later -- after the
  /// splash, the auth check and the router. A broadcast stream drops events
  /// that nobody is listening to yet, so without this the offer a driver
  /// deliberately tapped would vanish on the way to the screen that shows
  /// it.
  PresentableOffer? pendingOffer;

  /// True when a push is still waiting for socket details.
  bool isAwaitingDetails(int tripId) => _awaitingDetails.containsKey(tripId);

  /// Subscribe to the push transport. Safe to call when push is unavailable.
  Future<void> start() async {
    _subscriptions.add(
      _transport.onForegroundOffer.listen((offer) async {
        // Foreground: Android shows nothing by itself, so post a heads-up
        // notification as well. The socket almost certainly delivered the
        // same offer already, in which case this is a duplicate and the
        // decision below says so -- but the notification is still correct,
        // because a driver with the app open but the screen off needs it.
        final decision = onPushOffer(offer);
        if (decision != OfferDecision.stale) {
          await _transport.showOfferNotification(offer);
        }
      }),
    );

    _subscriptions.add(
      _transport.onOpenedOffer.listen((offer) => onPushOffer(offer)),
    );

    final initial = await _transport.takeInitialOffer();
    if (initial != null) {
      // The app was launched by a notification tap. Treated exactly like a
      // background tap: the trip is expected, and the socket owes details.
      onPushOffer(initial);
    }
  }

  /// A push announced an offer.
  OfferDecision onPushOffer(PushOffer offer) {
    final age = offer.ageAt(_now());
    if (age != null && age > offerLifetime) {
      AppLogger.i(
        'Push offer for trip ${offer.tripId} ignored: ${age.inSeconds}s old, '
        'past the ${offerLifetime.inSeconds}s accept timeout',
      );
      return lastDecision = OfferDecision.stale;
    }
    if (_settled.contains(offer.tripId)) {
      return lastDecision = OfferDecision.duplicate;
    }
    if (_hasActiveTrip()) {
      AppLogger.i(
        'Push offer for trip ${offer.tripId} ignored: already on a trip',
      );
      return lastDecision = OfferDecision.busy;
    }
    if (_awaitingDetails.containsKey(offer.tripId)) {
      return lastDecision = OfferDecision.duplicate;
    }

    _awaitingDetails[offer.tripId] = Timer(socketGrace, () {
      _awaitingDetails.remove(offer.tripId);
      if (_settled.contains(offer.tripId)) return;
      AppLogger.i(
        'Push offer for trip ${offer.tripId} expired: the dispatch socket '
        'never described it',
      );
      lastDecision = OfferDecision.expired;
      if (!_expired.isClosed) _expired.add(offer.tripId);
    });

    return lastDecision = OfferDecision.awaitingSocketDetails;
  }

  /// The dispatch socket delivered a `ride_request` frame.
  ///
  /// This is the only path that can present an offer, because it is the only
  /// one that carries the rider, the pickup and the fare.
  OfferDecision onSocketOffer(int tripId, Map<String, dynamic> payload) {
    if (_settled.contains(tripId)) {
      return lastDecision = OfferDecision.duplicate;
    }
    if (_hasActiveTrip()) {
      return lastDecision = OfferDecision.busy;
    }

    final expected = _awaitingDetails.remove(tripId);
    expected?.cancel();

    _settled.add(tripId);
    final offer = PresentableOffer(
      tripId: tripId,
      payload: payload,
      cameFromPush: expected != null,
    );
    pendingOffer = offer;
    if (!_offers.isClosed) _offers.add(offer);
    return lastDecision = OfferDecision.presented;
  }

  /// The driver accepted or declined, or the offer was withdrawn.
  ///
  /// Keeps the trip out of the sheet for the rest of the session, which is
  /// what stops a late push re-offering a ride the driver has already dealt
  /// with -- the case that would otherwise let them accept twice.
  void markSettled(int tripId) {
    _settled.add(tripId);
    _awaitingDetails.remove(tripId)?.cancel();
    if (pendingOffer?.tripId == tripId) pendingOffer = null;
  }

  /// Has this trip already been presented, accepted or declined?
  bool isSettled(int tripId) => _settled.contains(tripId);

  Future<void> dispose() async {
    for (final timer in _awaitingDetails.values) {
      timer.cancel();
    }
    _awaitingDetails.clear();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _offers.close();
    await _expired.close();
  }
}
