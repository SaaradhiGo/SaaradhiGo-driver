import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhigo_driver/core/notifications/offer_alert.dart';
import 'package:saaradhigo_driver/features/trip/presentation/trip_navigation.dart';
import 'package:saaradhigo_driver/shared/widgets/app_bottom_nav.dart';
import 'package:saaradhigo_driver/ui/driver_home_view.dart';
import 'package:saaradhigo_driver/ui/driver_trip_views.dart';

import '../support/driver_ui_fixtures.dart';

void main() {
  setUpAll(loadSgFonts);

  test('the tab bar is Home, Trips, Earnings, Profile', () {
    expect(AppBottomNav.items.map((i) => i.label),
        ['Home', 'Trips', 'Earnings', 'Profile']);
  });

  testWidgets('the Home bell carries a dot only when something is unread',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
        sgApp(Center(child: InboxBell(unread: 0, onTap: () => taps++))));
    expect(find.byKey(const Key('home_inbox_dot')), findsNothing);
    await tester.tap(find.byKey(const Key('home_inbox')));
    expect(taps, 1);
    await tester.pumpWidget(
        sgApp(Center(child: InboxBell(unread: 3, onTap: () {}))));
    expect(find.byKey(const Key('home_inbox_dot')), findsOneWidget);
    expect(find.bySemanticsLabel('Messages, 3 unread'), findsOneWidget);
  });

  test('the offer alert asks the platform once', () async {
    const channel = MethodChannel('saaradhigo/alert');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (c) async {
      calls.add(c.method);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await const OfferAlert().play();
    expect(calls, ['offer']);
  });

  test('money for cash is exact; road distance gives minutes', () {
    expect(exactMoney('150.00'), '₹150');
    expect(exactMoney('12.40'), '₹12.40');
    expect(roadLine(const []), isNull);
    expect(
      roadLine(const [LatLng(17.4400, 78.38), LatLng(17.4490, 78.38)]),
      '1.0 km · 4 min',
    );
  });

  test('PIN refusals read calmly', () {
    expect(pinErrorText('Invalid OTP provided', 'Raja Kumar'),
        'That PIN does not match. Ask Raja again.');
    expect(
        pinErrorText('Too many invalid OTP attempts. Ask the rider for the '
            'OTP again.', null),
        'Too many tries. Ask the rider to read the PIN again.');
    expect(pinErrorText(null, 'Raja'), isNull);
  });

  testWidgets('to pickup: first name, rating, distance, one gold action',
      (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.reset);
    var arrived = 0, cancelled = 0;
    await tester.pumpWidget(sgApp(toPickupFrame(
        onArrived: () => arrived++, onCancel: () => cancelled++)));
    expect(find.text('Raja'), findsOneWidget);
    expect(find.text('Raja Kumar'), findsNothing);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('1.2 km · 4 min'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    await tester.tap(find.text('I\'ve arrived'));
    await tester.tap(find.text('Cancel ride'));
    expect((arrived, cancelled), (1, 1));
  });

  group('PIN check', () {
    late TextEditingController c;
    Future<TextEditingController> pump(WidgetTester tester,
        {String? error, VoidCallback? onStart, VoidCallback? onMessage}) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(sgApp(StatefulBuilder(
        builder: (context, setState) => PinCheckView(
          controller: c,
          riderName: 'Raja Kumar',
          pickupAddress: 'Ameerpet Metro Station',
          error: error,
          onStart: onStart ?? () {},
          onCancel: () {},
          onMessage: onMessage,
          onChanged: (_) => setState(() {}),
        ),
      )));
      return c;
    }

    testWidgets('Start stays off until all six digits are in',
        (tester) async {
      var started = 0;
      await pump(tester, onStart: () => started++);
      expect(find.text('Ask Raja for the trip PIN'), findsOneWidget);
      expect(find.text('At pickup'), findsOneWidget);
      expect(find.byKey(const Key('pin_box_5')), findsOneWidget);
      expect(find.byKey(const Key('pin_box_6')), findsNothing);
      expect(tester.getSize(find.byKey(const Key('pin_box_0'))).height, 72);
      expect(tester.getSize(find.byKey(const Key('pin_key_1'))).height, 64);
      expect(tester.getSize(find.byKey(const Key('trip_start'))).height, 72);
      for (final d in '1234'.split('')) {
        await tester.tap(find.byKey(Key('pin_key_$d')));
      }
      await tester.pump();
      await tester.tap(find.text('Start trip'));
      expect(started, 0);
      await tester.tap(find.byKey(const Key('pin_key_5')));
      await tester.tap(find.byKey(const Key('pin_key_delete')));
      await tester.tap(find.byKey(const Key('pin_key_5')));
      await tester.tap(find.byKey(const Key('pin_key_6')));
      await tester.tap(find.byKey(const Key('pin_key_7')));
      await tester.pump();
      expect(c.text, '123456');
      await tester.tap(find.text('Start trip'));
      expect(started, 1);
    });

    testWidgets('the rider row carries a 56px message button',
        (tester) async {
      var messaged = 0;
      await pump(tester, onMessage: () => messaged++);
      expect(tester.getSize(find.byKey(const Key('trip_message'))),
          const Size(56, 56));
      await tester.tap(find.byKey(const Key('trip_message')));
      expect(messaged, 1);
    });

    testWidgets('a wrong PIN says so calmly', (tester) async {
      await pump(tester, error: 'That PIN does not match. Ask again.');
      expect(find.byKey(const Key('trip_pin_error')), findsOneWidget);
    });
  });

  testWidgets('in trip: the drop, what is left, the fare, Complete',
      (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.reset);
    var done = 0;
    await tester.pumpWidget(sgApp(inTripFrame(onComplete: () => done++)));
    expect(find.text('ON TRIP WITH RAJA'), findsOneWidget);
    expect(find.text('Hitech City, Madhapur'), findsOneWidget);
    expect(find.text('8.4 km · 20 min'), findsOneWidget);
    expect(find.text('₹248'), findsOneWidget);
    await tester.tap(find.text('Complete trip'));
    expect(done, 1);
  });

  testWidgets('complete with cash: collect first, then Done', (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.reset);
    var confirmed = 0;
    await tester.pumpWidget(
        sgApp(completeFrame(onConfirmCash: () => confirmed++)));
    expect(find.text('COLLECT IN CASH'), findsOneWidget);
    expect(find.textContaining('Collect ₹248 cash from Raja'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    await tester.tap(find.text('Cash collected'));
    expect(confirmed, 1);
    expect(find.text('Rate Raja'), findsOneWidget);
  });

  testWidgets('complete and paid online: the fare and who paid',
      (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(sgApp(completeFrame(cash: false)));
    expect(find.text('Paid by UPI'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('COLLECT IN CASH'), findsNothing);
  });
}
