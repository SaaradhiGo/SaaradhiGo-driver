/// One offer, two channels, one bottom sheet.
///
/// `servers/ride/dispatch.py` announces every offer twice on purpose: a
/// `ride_request` frame on the dispatch WebSocket, and an FCM push to the
/// same driver. The socket only reaches a running, connected app; push is
/// what reaches a backgrounded or terminated one. Both can arrive for the
/// same trip, and without one arbiter the driver gets the sheet twice -- and
/// can accept twice.
///
/// These tests cover the arbiter: deduplication across both channels, the
/// staleness bound taken from the backend's own `TRIP_ACCEPT_TIMEOUT_SECONDS`
/// (90s, after which `auto_cancel_trip` has closed the trip regardless), the
/// push-then-socket handoff that a tapped notification depends on, and the
/// settled-trip rule that stops a late push re-offering a ride the driver has
/// already dealt with.
library;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/notifications/push_offer.dart';
import 'package:saaradhigo_driver/core/notifications/ride_offer_coordinator.dart';

import 'fake_push_transport.dart';

void main() {
  late FakePushTransport transport;
  late DateTime clock;
  bool busy = false;

  /// The payload the dispatch socket sends.
  Map<String, dynamic> socketPayload(int tripId) => {
    'type': 'ride_request',
    'trip_id': tripId,
    'rider_name': 'Test Rider',
    'pickup': 'Koramangala',
  };

  PushOffer pushOffer(
    int tripId, {
    PushOfferSource source = PushOfferSource.foreground,
    Duration age = Duration.zero,
  }) => PushOffer(tripId: tripId, source: source, sentAt: clock.subtract(age));

  RideOfferCoordinator build() => RideOfferCoordinator(
    transport: transport,
    hasActiveTrip: () => busy,
    now: () => clock,
  );

  setUp(() {
    transport = FakePushTransport();
    clock = DateTime.utc(2026, 10, 17, 12, 0, 0);
    busy = false;
  });

  group('the socket presents offers, because only it has the details', () {
    test('a socket frame is presented', () async {
      final coordinator = build();
      addTearDown(coordinator.dispose);

      final presented = <PresentableOffer>[];
      coordinator.offers.listen(presented.add);

      final decision = coordinator.onSocketOffer(42, socketPayload(42));
      await pumpEventQueue();

      expect(decision, OfferDecision.presented);
      expect(presented, hasLength(1));
      expect(presented.single.tripId, 42);
      expect(presented.single.payload['rider_name'], 'Test Rider');
      expect(presented.single.cameFromPush, isFalse);
    });

    test('the same trip is never presented twice', () async {
      // Dispatch runs up to three waves; a driver in range of more than one
      // can be offered the same trip again.
      final coordinator = build();
      addTearDown(coordinator.dispose);

      final presented = <PresentableOffer>[];
      coordinator.offers.listen(presented.add);

      coordinator.onSocketOffer(42, socketPayload(42));
      final second = coordinator.onSocketOffer(42, socketPayload(42));
      await pumpEventQueue();

      expect(second, OfferDecision.duplicate);
      expect(presented, hasLength(1));
    });

    test('nothing is presented while the driver is on a trip', () async {
      busy = true;
      final coordinator = build();
      addTearDown(coordinator.dispose);

      final presented = <PresentableOffer>[];
      coordinator.offers.listen(presented.add);

      expect(
        coordinator.onSocketOffer(42, socketPayload(42)),
        OfferDecision.busy,
      );
      await pumpEventQueue();
      expect(presented, isEmpty);
    });
  });

  group('a push announces; the socket describes', () {
    test('a push alone does not present an offer', () {
      // It cannot: the payload is {trip_id, type}, and
      // GET /ride/trip/<id>/ refuses a driver who is not yet assigned, so
      // there is no way to learn the rider, the pickup or the fare.
      final coordinator = build();
      addTearDown(coordinator.dispose);

      final decision = coordinator.onPushOffer(pushOffer(42));

      expect(decision, OfferDecision.awaitingSocketDetails);
      expect(coordinator.isAwaitingDetails(42), isTrue);
    });

    test(
      'the socket frame that follows is presented, and marked as expected',
      () async {
        final coordinator = build();
        addTearDown(coordinator.dispose);

        final presented = <PresentableOffer>[];
        coordinator.offers.listen(presented.add);

        coordinator.onPushOffer(
          pushOffer(42, source: PushOfferSource.openedFromTerminated),
        );
        coordinator.onSocketOffer(42, socketPayload(42));
        await pumpEventQueue();

        expect(
          presented.single.cameFromPush,
          isTrue,
          reason:
              'the driver tapped a notification and is expecting this, so '
              'the app should go straight to it',
        );
        expect(coordinator.isAwaitingDetails(42), isFalse);
      },
    );

    test('a second push for the same trip changes nothing', () {
      final coordinator = build();
      addTearDown(coordinator.dispose);

      coordinator.onPushOffer(pushOffer(42));
      expect(coordinator.onPushOffer(pushOffer(42)), OfferDecision.duplicate);
    });

    test('a push for a trip already presented is ignored', () {
      // The ordinary case: the socket got there first, then the push lands.
      final coordinator = build();
      addTearDown(coordinator.dispose);

      coordinator.onSocketOffer(42, socketPayload(42));

      expect(coordinator.onPushOffer(pushOffer(42)), OfferDecision.duplicate);
    });

    test('an announced offer the socket never describes expires', () {
      fakeAsync((async) {
        final coordinator = RideOfferCoordinator(
          transport: transport,
          hasActiveTrip: () => busy,
          now: () => clock,
          socketGrace: const Duration(seconds: 12),
        );

        final expired = <int>[];
        coordinator.expiredOffers.listen(expired.add);

        coordinator.onPushOffer(pushOffer(42));
        async.elapse(const Duration(seconds: 13));

        expect(
          expired,
          [42],
          reason:
              'the driver must be told the ride is gone, not left '
              'looking at a screen that never fills in',
        );
        expect(coordinator.isAwaitingDetails(42), isFalse);
      });
    });

    test('a described offer does not then expire', () {
      fakeAsync((async) {
        final coordinator = RideOfferCoordinator(
          transport: transport,
          hasActiveTrip: () => busy,
          now: () => clock,
          socketGrace: const Duration(seconds: 12),
        );

        final expired = <int>[];
        coordinator.expiredOffers.listen(expired.add);

        coordinator.onPushOffer(pushOffer(42));
        coordinator.onSocketOffer(42, socketPayload(42));
        async.elapse(const Duration(seconds: 30));

        expect(expired, isEmpty);
      });
    });
  });

  group('stale offers are dropped without waking anyone', () {
    test('a push older than the accept timeout is ignored', () {
      // 90s is TRIP_ACCEPT_TIMEOUT_SECONDS: after it, auto_cancel_trip has
      // closed the trip whatever the driver does.
      final coordinator = build();
      addTearDown(coordinator.dispose);

      final decision = coordinator.onPushOffer(
        pushOffer(42, age: const Duration(seconds: 91)),
      );

      expect(decision, OfferDecision.stale);
      expect(coordinator.isAwaitingDetails(42), isFalse);
    });

    test('a notification tapped hours later is ignored', () {
      // The real case: an offer sitting in the shade overnight.
      final coordinator = build();
      addTearDown(coordinator.dispose);

      expect(
        coordinator.onPushOffer(
          pushOffer(
            42,
            source: PushOfferSource.openedFromTerminated,
            age: const Duration(hours: 8),
          ),
        ),
        OfferDecision.stale,
      );
    });

    test('an offer inside the window is accepted', () {
      final coordinator = build();
      addTearDown(coordinator.dispose);

      expect(
        coordinator.onPushOffer(
          pushOffer(42, age: const Duration(seconds: 20)),
        ),
        OfferDecision.awaitingSocketDetails,
      );
    });

    test('a push with no send time is not assumed stale', () {
      // FCM does not always provide sentTime. Dropping those would mean
      // dropping real offers; the socket handoff and the settled rule still
      // protect the driver.
      final coordinator = build();
      addTearDown(coordinator.dispose);

      expect(
        coordinator.onPushOffer(
          const PushOffer(tripId: 42, source: PushOfferSource.foreground),
        ),
        OfferDecision.awaitingSocketDetails,
      );
    });
  });

  group('a settled trip cannot be re-offered', () {
    test('after accepting, a late push is ignored', () {
      // This is the duplicate-acceptance case. The driver accepted over the
      // trip socket; a wave-two push for the same trip must not put the sheet
      // back up and invite a second accept.
      final coordinator = build();
      addTearDown(coordinator.dispose);

      coordinator.onSocketOffer(42, socketPayload(42));
      coordinator.markSettled(42);

      expect(coordinator.onPushOffer(pushOffer(42)), OfferDecision.duplicate);
      expect(
        coordinator.onSocketOffer(42, socketPayload(42)),
        OfferDecision.duplicate,
      );
    });

    test('after declining, the same trip is not offered again', () async {
      final coordinator = build();
      addTearDown(coordinator.dispose);

      final presented = <PresentableOffer>[];
      coordinator.offers.listen(presented.add);

      coordinator.onSocketOffer(42, socketPayload(42));
      coordinator.markSettled(42);
      coordinator.onSocketOffer(42, socketPayload(42));
      await pumpEventQueue();

      expect(presented, hasLength(1));
      expect(coordinator.isSettled(42), isTrue);
    });

    test('settling one trip does not block a different one', () async {
      final coordinator = build();
      addTearDown(coordinator.dispose);

      final presented = <PresentableOffer>[];
      coordinator.offers.listen(presented.add);

      coordinator.onSocketOffer(42, socketPayload(42));
      coordinator.markSettled(42);
      coordinator.onSocketOffer(99, socketPayload(99));
      await pumpEventQueue();

      expect(presented.map((o) => o.tripId), [42, 99]);
    });

    test('settling cancels a pending push wait', () {
      fakeAsync((async) {
        final coordinator = RideOfferCoordinator(
          transport: transport,
          hasActiveTrip: () => busy,
          now: () => clock,
          socketGrace: const Duration(seconds: 12),
        );

        final expired = <int>[];
        coordinator.expiredOffers.listen(expired.add);

        coordinator.onPushOffer(pushOffer(42));
        coordinator.markSettled(42);
        async.elapse(const Duration(seconds: 30));

        expect(
          expired,
          isEmpty,
          reason:
              'a trip the driver has dealt with must not then be '
              'reported as expired',
        );
      });
    });
  });

  group('start() wires the transport', () {
    test('a foreground push also posts a heads-up notification', () async {
      // Android does not display a notification for a message that arrives
      // in the foreground, so a driver with the app open and the screen off
      // would see nothing at all.
      final coordinator = build();
      addTearDown(coordinator.dispose);

      await coordinator.start();
      transport.foreground.add(pushOffer(42));
      await pumpEventQueue();

      expect(transport.shownNotifications.map((o) => o.tripId), [42]);
    });

    test('a stale foreground push posts nothing', () async {
      final coordinator = build();
      addTearDown(coordinator.dispose);

      await coordinator.start();
      transport.foreground.add(pushOffer(42, age: const Duration(minutes: 10)));
      await pumpEventQueue();

      expect(transport.shownNotifications, isEmpty);
    });

    test('a launch notification is taken and announced', () async {
      // The terminated-app case: the driver tapped a notification and the app
      // was not running.
      transport.initialOffer = pushOffer(
        77,
        source: PushOfferSource.openedFromTerminated,
      );
      final coordinator = build();
      addTearDown(coordinator.dispose);

      await coordinator.start();

      expect(transport.initialOfferReads, 1);
      expect(
        coordinator.isAwaitingDetails(77),
        isTrue,
        reason:
            'the app should connect the dispatch socket and go to the '
            'offer as soon as it is described',
      );
    });

    test('a tap on a background notification is announced', () async {
      final coordinator = build();
      addTearDown(coordinator.dispose);

      await coordinator.start();
      transport.opened.add(
        pushOffer(88, source: PushOfferSource.openedFromBackground),
      );
      await pumpEventQueue();

      expect(coordinator.isAwaitingDetails(88), isTrue);
    });

    test('start() is safe when there is no launch notification', () async {
      final coordinator = build();
      addTearDown(coordinator.dispose);

      await expectLater(coordinator.start(), completes);
      expect(coordinator.lastDecision, isNull);
    });
  });
}
