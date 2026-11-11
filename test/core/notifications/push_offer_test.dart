/// Parsing the dispatch push payload, as the server actually sends it.
///
/// `servers/ride/dispatch.py::_enqueue_offer_pushes` sends
/// `{'trip_id': str(trip_id), 'type': 'ride_request'}`, and
/// `send_push_notification_task` stringifies every value before handing it to
/// FCM (`{str(k): str(v) for ...}`). So `trip_id` arrives as a **String**,
/// while the WebSocket frame carries the same field as an **int**.
///
/// That difference is invisible until a driver taps a notification and
/// nothing happens, which is why it is pinned here rather than assumed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/notifications/push_offer.dart';

void main() {
  PushOffer? parse(Map<String, dynamic> data) =>
      PushOffer.tryParse(data, source: PushOfferSource.foreground);

  group('the payload dispatch really sends', () {
    test('a stringified trip id is parsed', () {
      final offer = parse({'trip_id': '4210', 'type': 'ride_request'});

      expect(offer, isNotNull);
      expect(offer!.tripId, 4210);
    });

    test('an int trip id is parsed too', () {
      // The WebSocket frame's shape. Both channels feed the same coordinator,
      // so both have to parse.
      expect(parse({'trip_id': 4210, 'type': 'ride_request'})?.tripId, 4210);
    });

    test('surrounding whitespace does not defeat it', () {
      expect(
        parse({'trip_id': ' 4210 ', 'type': 'ride_request'})?.tripId,
        4210,
      );
    });
  });

  group('anything else is ignored rather than fatal', () {
    test('a different notification type is not an offer', () {
      // Trip updates, ops alerts and marketing come through the same channel.
      expect(parse({'trip_id': '1', 'type': 'trip_status'}), isNull);
      expect(parse({'type': 'promo'}), isNull);
      expect(parse(const <String, dynamic>{}), isNull);
    });

    test('a ride_request with no usable trip id is not an offer', () {
      expect(parse({'type': 'ride_request'}), isNull);
      expect(parse({'trip_id': '', 'type': 'ride_request'}), isNull);
      expect(
        parse({'trip_id': 'not-a-number', 'type': 'ride_request'}),
        isNull,
      );
      expect(parse({'trip_id': null, 'type': 'ride_request'}), isNull);
    });

    test('a hostile payload cannot throw', () {
      // A push is attacker-adjacent input: anything that reaches the parser
      // must not be able to crash the app on a driver's phone.
      expect(
        () => parse({
          'trip_id': {'nested': 'object'},
          'type': 'ride_request',
        }),
        returnsNormally,
      );
      expect(
        () => parse({
          'trip_id': ['1'],
          'type': 'ride_request',
        }),
        returnsNormally,
      );
    });
  });

  group('how the driver got here', () {
    test('a foreground arrival was not tapped', () {
      final offer = PushOffer.tryParse({
        'trip_id': '1',
        'type': 'ride_request',
      }, source: PushOfferSource.foreground);
      expect(offer!.wasTapped, isFalse);
    });

    test('a background or terminated arrival was tapped', () {
      for (final source in [
        PushOfferSource.openedFromBackground,
        PushOfferSource.openedFromTerminated,
      ]) {
        final offer = PushOffer.tryParse({
          'trip_id': '1',
          'type': 'ride_request',
        }, source: source);
        expect(
          offer!.wasTapped,
          isTrue,
          reason: '$source means the driver acted on the notification',
        );
      }
    });
  });

  group('age', () {
    test('is measured from the time FCM says the server sent it', () {
      final sent = DateTime.utc(2026, 10, 17, 12, 0, 0);
      final offer = PushOffer.tryParse(
        {'trip_id': '1', 'type': 'ride_request'},
        source: PushOfferSource.openedFromTerminated,
        sentAt: sent,
      );

      expect(
        offer!.ageAt(sent.add(const Duration(seconds: 45))),
        const Duration(seconds: 45),
      );
    });

    test('is unknown when FCM gave no send time', () {
      final offer = PushOffer.tryParse({
        'trip_id': '1',
        'type': 'ride_request',
      }, source: PushOfferSource.foreground);
      expect(offer!.ageAt(DateTime.now()), isNull);
    });

    test('clock skew does not produce a negative age', () {
      // A phone whose clock is behind the server's would otherwise report a
      // negative age, which would compare as "fresh" by accident.
      final sent = DateTime.utc(2026, 10, 17, 12, 0, 0);
      final offer = PushOffer.tryParse(
        {'trip_id': '1', 'type': 'ride_request'},
        source: PushOfferSource.foreground,
        sentAt: sent,
      );

      expect(
        offer!.ageAt(sent.subtract(const Duration(minutes: 5))),
        Duration.zero,
      );
    });
  });
}
