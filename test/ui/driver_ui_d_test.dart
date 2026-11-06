import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/ui/driver_home_view.dart';
import 'package:saaradhigo_driver/ui/incoming_offer_card.dart';

import '../support/driver_ui_fixtures.dart';

Future<void> pumpOffer(
  WidgetTester tester, {
  Map<String, dynamic> payload = sampleOffer,
  VoidCallback? onAccept,
  VoidCallback? onDecline,
  VoidCallback? onExpired,
}) async {
  setPhoneSurface(tester);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(sgApp(IncomingOfferCard(
    payload: payload,
    alert: false,
    mapProvider: kPlaceholderMaps,
    onAccept: onAccept ?? () {},
    onDecline: onDecline ?? () {},
    onExpired: onExpired ?? () {},
  )));
  await tester.pump();
}

void main() {
  setUpAll(loadSgFonts);

  group('home', () {
    testWidgets('offline shows the pill and a gold Go online', (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      var tapped = 0;
      await tester.pumpWidget(sgApp(homeFrame(onGoOnline: () => tapped++)));
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Go online'), findsOneWidget);
      expect(find.text('Go offline'), findsNothing);
      expect(find.text('₹1,240'), findsOneWidget);
      await tester.tap(find.text('Go online'));
      expect(tapped, 1);
    });

    testWidgets('online shows the pill, Go offline and the calm line',
        (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      var tapped = 0;
      await tester.pumpWidget(
          sgApp(homeFrame(online: true, onGoOffline: () => tapped++)));
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Go offline'), findsOneWidget);
      expect(find.text('Go online'), findsNothing);
      expect(find.text('Looking for rides near you'), findsOneWidget);
      expect(find.text('1h 12m'), findsOneWidget);
      await tester.tap(find.text('Go offline'));
      expect(tapped, 1);
    });

    testWidgets('a blocker replaces Go online and carries its action',
        (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      var acted = 0;
      await tester.pumpWidget(sgApp(homeFrame(
        blocker: HomeBlocker(
          title: 'Verification in progress',
          body: 'You can go online once your documents are approved.',
          actionLabel: 'Check status',
          onAction: () => acted++,
        ),
      )));
      expect(find.text('Go online'), findsNothing);
      expect(find.text('Verification in progress'), findsOneWidget);
      await tester.tap(find.text('Check status'));
      expect(acted, 1);
    });

    test('money is whole units with Indian grouping', () {
      expect(wholeMoney('247.80'), '₹248');
      expect(wholeMoney('124000.20'), '₹1,24,000');
      expect(wholeMoney('abc'), isNull);
    });
  });

  group('incoming offer', () {
    testWidgets('shows the fare in whole rupees and the pickup distance',
        (tester) async {
      await pumpOffer(tester);
      expect(find.text('₹248'), findsOneWidget);
      expect(find.text('Sedan · Cash'), findsOneWidget);
      expect(find.text('1.2 km · 4 min away'), findsOneWidget);
      expect(find.text('8.4 km · 20 min'), findsOneWidget);
      expect(find.text('Ameerpet Metro Station'), findsOneWidget);
      expect(find.text('Hitech City, Madhapur'), findsOneWidget);
    });

    testWidgets('leaves out lines the frame does not carry', (tester) async {
      await pumpOffer(tester, payload: const {
        'trip_id': 3,
        'estimated_fare': '90',
        'pickup_address': 'A',
        'destination_address': 'B',
      });
      expect(find.text('₹90'), findsOneWidget);
      expect(find.textContaining('away'), findsNothing);
      expect(find.textContaining('Cash'), findsNothing);
    });

    testWidgets('the countdown decreases each second', (tester) async {
      await pumpOffer(tester);
      expect(find.text('20'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('17'), findsOneWidget);
      expect(find.text('20'), findsNothing);
    });

    testWidgets('an expires_at in the frame sets the countdown',
        (tester) async {
      final soon = DateTime.now().add(const Duration(seconds: 31));
      await pumpOffer(tester, payload: {
        ...sampleOffer,
        'expires_at': soon.toUtc().toIso8601String(),
      });
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('Accept and Decline call through', (tester) async {
      var accepted = 0, declined = 0;
      await pumpOffer(
        tester,
        onAccept: () => accepted++,
        onDecline: () => declined++,
      );
      await tester.tap(find.text('Accept'));
      await tester.tap(find.text('Decline'));
      expect(accepted, 1);
      expect(declined, 1);
    });

    testWidgets('on expiry the card says so and then closes', (tester) async {
      var expired = 0;
      await pumpOffer(tester, onExpired: () => expired++);
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('Offer expired'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(expired, 0);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(expired, 1);
    });
  });
}
