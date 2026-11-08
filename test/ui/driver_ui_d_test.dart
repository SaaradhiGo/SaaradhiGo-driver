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
    testWidgets('offline: the dark sheet, the pill and Go online',
        (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      var tapped = 0;
      await tester.pumpWidget(sgApp(homeFrame(onGoOnline: () => tapped++)));
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text('Requests appear here when you go online.'),
          findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('DRIVER'), findsOneWidget);
      expect(find.text('Go online'), findsOneWidget);
      expect(find.text('Go offline'), findsNothing);
      expect(find.text('₹1,240'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      await tester.tap(find.text('Go online'));
      expect(tapped, 1);
    });

    testWidgets('online: the title, the calm line and Go offline',
        (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      var tapped = 0;
      await tester.pumpWidget(
          sgApp(homeFrame(online: true, onGoOffline: () => tapped++)));
      expect(find.text("You're online"), findsOneWidget);
      expect(find.text('Looking for rides near you · 1h 12m'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Go offline'), findsOneWidget);
      expect(find.text('Go online'), findsNothing);
      await tester.tap(find.text('Go offline'));
      expect(tapped, 1);
    });

    testWidgets('today: earned in gold at 28, trips beside it',
        (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(sgApp(homeFrame(commission: '₹310')));
      expect(find.text('Today you earned'), findsOneWidget);
      expect(find.text('Trips today'), findsOneWidget);
      final amount = tester.widget<Text>(find.byKey(const Key('home_earnings')));
      expect(amount.data, '₹1,240');
      expect(amount.style!.fontSize, 28);
    });

    testWidgets('Go online is 72px', (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(sgApp(homeFrame()));
      expect(
          tester.getSize(find.byKey(const Key('home_go_online'))).height, 72);
    });

    testWidgets('a blocker shows as a card and disables Go online',
        (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      var acted = 0, online = 0;
      await tester.pumpWidget(sgApp(homeFrame(
        onGoOnline: () => online++,
        blocker: HomeBlocker(
          title: 'Verification in progress',
          body: 'You can go online once your documents are approved.',
          actionLabel: 'Check status',
          onAction: () => acted++,
        ),
      )));
      expect(find.text('Verification in progress'), findsOneWidget);
      await tester.tap(find.text('Go online'));
      expect(online, 0);
      await tester.tap(find.text('Check status'));
      expect(acted, 1);
    });

    test('money is whole units with Indian grouping', () {
      expect(wholeMoney('247.80'), '₹248');
      expect(wholeMoney('124000.20'), '₹1,24,000');
      expect(wholeMoney('abc'), isNull);
    });
  });

  group('offer helpers', () {
    test('the area is the part before the first comma', () {
      expect(splitArea('Ameerpet Metro Station, Gate 2, Hyderabad'),
          ('Ameerpet Metro Station', 'Gate 2, Hyderabad'));
      expect(splitArea('Hitech City'), ('Hitech City', null));
      expect(splitArea(' Madhapur , '), ('Madhapur', null));
    });

    test('commission rate reads as a percentage', () {
      expect(percentText('20.00'), '20');
      expect(percentText('12.50'), '12.5');
      expect(percentText(0.2), '20');
      expect(percentText(null), isNull);
      expect(percentText('x'), isNull);
    });

    test('the earning is the frame\'s own, never worked out', () {
      final none = OfferData.fromPayload(sampleOffer);
      expect(none.earning, isNull);
      expect(none.hasFareLine, isFalse);
      final o = OfferData.fromPayload(sampleOfferWithEarning);
      expect(o.earning, '₹198');
      expect(o.fare, '₹248');
      expect(o.commissionPercent, '20');
      expect(o.commissionAmount, '₹50');
      expect(o.riderRating, 4.8);
      expect(o.hasFareLine, isTrue);
    });
  });

  group('incoming offer', () {
    testWidgets('without an earning: the fare row, no You earn',
        (tester) async {
      await pumpOffer(tester);
      expect(find.text('NEW RIDE REQUEST'), findsOneWidget);
      expect(find.text('Sedan · 1.2 km to pickup'), findsOneWidget);
      expect(find.text('Trip fare'), findsOneWidget);
      expect(find.text('You earn'), findsNothing);
      expect(find.byKey(const Key('offer_commission_row')), findsNothing);
      expect(find.text('Pickup · Ameerpet Metro Station'), findsOneWidget);
      expect(find.text('Drop · Hitech City'), findsOneWidget);
    });

    testWidgets('with an earning: fare, commission and You earn',
        (tester) async {
      await pumpOffer(tester, payload: sampleOfferWithEarning);
      expect(find.text('You earn'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('offer_amount'))).data,
          '₹198');
      expect(find.text('₹248'), findsOneWidget);
      expect(find.text('− ₹50'), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('offer_accept'))).height, 64);
    });

    testWidgets('leaves out what the frame does not carry', (tester) async {
      await pumpOffer(tester, payload: const {
        'trip_id': 3,
        'estimated_fare': '90',
        'pickup_address': 'A',
        'destination_address': 'B',
      });
      expect(tester.widget<Text>(find.byKey(const Key('offer_amount'))).data,
          '₹90');
      expect(find.byKey(const Key('offer_headline')), findsNothing);
      expect(find.byKey(const Key('offer_earn_row')), findsNothing);
    });

    testWidgets('the countdown decreases each second', (tester) async {
      await pumpOffer(tester);
      expect(find.text('20s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('17s'), findsOneWidget);
      expect(find.text('20s'), findsNothing);
    });

    testWidgets('an expires_at in the frame sets the countdown',
        (tester) async {
      final soon = DateTime.now().add(const Duration(seconds: 31));
      await pumpOffer(tester, payload: {
        ...sampleOffer,
        'expires_at': soon.toUtc().toIso8601String(),
      });
      expect(find.text('30s'), findsOneWidget);
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
