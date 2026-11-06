// Daylight + adaptive type (owner brief, 6 Nov 2026): the main driver
// screens at 320 wide and 1.3x text, in light and dark, raise no overflow;
// the type scale follows the size class; the light tokens are the brief's.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/storage/local_storage_service.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip/presentation/widgets/ride_cancelled_bottom_sheet.dart';
import 'package:saaradhigo_driver/ui/driver_earnings_view.dart';
import 'package:saaradhigo_driver/ui/driver_f_logic.dart';
import 'package:saaradhigo_driver/ui/driver_trip_views.dart';
import 'package:saaradhigo_driver/ui/incoming_offer_card.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';
import 'package:saaradhigo_driver/ui/sg_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/driver_ui_fixtures.dart';

Widget _pin() => PinCheckView(
      controller: TextEditingController(text: '12'),
      riderName: 'Raja Kumar',
      riderRating: 4.8,
      pickupAddress: 'Ameerpet Metro Station',
      onStart: () {},
      onCancel: () {},
      onMessage: () {},
    );

Widget _earnings() => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const EarningsNoirPanel(
          periodLabel: 'Today',
          trips: 3,
          amount: '₹12,364',
          isNet: true,
          commission: '₹1,864',
          commissionRate: '15%',
        ),
        const SizedBox(height: 16),
        EarningsWeekChart(
          days: parseDailyEarnings(sampleDailyBody)!,
          money: (v) => '₹${v.round()}',
        ),
        const SizedBox(height: 16),
        WithdrawPanel(
          balance: '₹1,240',
          canWithdraw: true,
          payoutMissing: true,
          onWithdraw: () {},
          onAddPayout: () {},
        ),
      ],
    );

final _screens = <String, Widget Function()>{
  'home online': () => homeFrame(online: true),
  'home offline': () => homeFrame(),
  'offer': () => IncomingOfferCard(
        payload: sampleOfferWithEarning,
        alert: false,
        mapProvider: kPlaceholderMaps,
        onAccept: () {},
        onDecline: () {},
        onExpired: () {},
      ),
  'to pickup': () => toPickupFrame(),
  'PIN': _pin,
  'on trip': () => inTripFrame(),
  'complete': () => completeFrame(),
  'earnings': _earnings,
  'cancelled': () => RideCancelledBottomSheet(
        reason: 'Rider changed plans',
        actor: CancelActor.rider,
        autoDismissSeconds: 0,
        onDismiss: () {},
      ),
};

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required Size logical,
  double textScale = 1.0,
}) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = logical * 3.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SgText.useShortestSide(logical.shortestSide);
  await tester.pumpWidget(sgApp(child));
  await tester.pump();
  final ctx = tester.element(find.byType(Scaffold).first);
  expect(MediaQuery.textScalerOf(ctx).scale(10), closeTo(10 * textScale, 0.01));
  expect(MediaQuery.sizeOf(ctx), logical);
}

void main() {
  setUpAll(loadSgFonts);
  tearDown(() {
    SgColors.use(SgPalette.dark);
    SgText.useShortestSide(390);
  });

  for (final palette in [SgPalette.light, SgPalette.dark]) {
    for (final entry in _screens.entries) {
      testWidgets(
          '${entry.key} at 320 wide and 1.3x text, '
          '${palette.isDark ? 'dark' : 'light'}: no overflow', (tester) async {
        SgColors.use(palette);
        await _pump(tester, entry.value(),
            logical: const Size(320, 640), textScale: 1.3);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final entry in _screens.entries) {
    testWidgets('${entry.key} on a landscape phone: no overflow',
        (tester) async {
      SgColors.use(SgPalette.light);
      await _pump(tester, entry.value(), logical: const Size(844, 390));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tablet: the offer and the PIN are centred cards, 480 wide',
      (tester) async {
    SgColors.use(SgPalette.light);
    await _pump(tester, _screens['offer']!(), logical: const Size(800, 1280));
    expect(tester.takeException(), isNull);
    final offer = tester.getRect(find.byKey(const Key('offer_tablet_card')));
    expect(offer.width, lessThanOrEqualTo(480));
    expect(offer.center.dx, closeTo(400, 1));

    await _pump(tester, _pin(), logical: const Size(800, 1280));
    final pin = tester.getRect(find.byKey(const Key('pin_tablet_card')));
    expect(pin.width, lessThanOrEqualTo(480));
    expect(pin.center.dx, closeTo(400, 1));
  });

  group('type scale', () {
    test('size classes from the shortest side', () {
      expect(SgSizeClass.of(320), SgSizeClass.compact);
      expect(SgSizeClass.of(359), SgSizeClass.compact);
      expect(SgSizeClass.of(360), SgSizeClass.regular);
      expect(SgSizeClass.of(599), SgSizeClass.regular);
      expect(SgSizeClass.of(600), SgSizeClass.tablet);
    });

    test('the brief\'s sizes and weights per class', () {
      SgText.useShortestSide(390);
      expect(SgText.screenTitle.fontSize, 24);
      expect(SgText.sectionTitle.fontSize, 18);
      expect(SgText.body.fontSize, 16);
      expect(SgText.caption.fontSize, 14);
      expect(SgText.label.fontSize, 13);
      expect(SgText.button.fontSize, 17);
      expect(SgText.bigFare.fontSize, 44);
      expect(SgText.driverEarning.fontSize, 64);
      SgText.useShortestSide(320);
      expect(SgText.bigFare.fontSize, closeTo(40, 0.01));
      expect(SgText.driverEarning.fontSize, closeTo(56, 0.01));
      expect(SgText.body.fontSize, closeTo(16 * 0.92, 0.01));
      SgText.useShortestSide(800);
      expect(SgText.screenTitle.fontSize, closeTo(24 * 1.12, 0.01));
      for (final s in [
        SgText.screenTitle,
        SgText.sectionTitle,
        SgText.body,
        SgText.caption,
        SgText.label,
        SgText.button,
        SgText.bigFare,
        SgText.driverEarning,
      ]) {
        expect(
          [FontWeight.w500, FontWeight.w600, FontWeight.w700],
          contains(s.fontWeight),
        );
        expect(s.letterSpacing, 0);
      }
    });
  });

  test('light tokens are the brief\'s', () {
    const p = SgPalette.light;
    expect(p.bg000, const Color(0xFFFAF7F2));
    expect(p.bg100, const Color(0xFFFFFFFF));
    expect(p.gold500, const Color(0xFFF5A623));
    expect(p.onGold, const Color(0xFF1B1A17));
    expect(p.goldText, const Color(0xFF8A5300));
    expect(p.logo, const Color(0xFF7A6000));
    expect(p.pickup, const Color(0xFF0D7762));
    expect(p.danger, const Color(0xFFB3261E));
  });

  group('cancel actor (Tier 4)', () {
    test('only the server\'s cancelled_by names who cancelled', () {
      expect(CancelActor.fromServer('driver'), CancelActor.you);
      expect(CancelActor.fromServer('rider'), CancelActor.rider);
      for (final other in [null, '', 'system', 'admin', 'x']) {
        expect(CancelActor.fromServer(other), CancelActor.unknown);
      }
    });

    for (final (actor, title) in [
      (CancelActor.you, 'Cancelled by you'),
      (CancelActor.rider, 'Cancelled by the rider'),
      (CancelActor.unknown, 'Trip cancelled'),
    ]) {
      testWidgets('the cancelled sheet says "$title"', (tester) async {
        await tester.pumpWidget(sgApp(RideCancelledBottomSheet(
          actor: actor,
          autoDismissSeconds: 0,
          onDismiss: () {},
        )));
        expect(find.text(title), findsOneWidget);
      });
    }
  });

  group('active trip (Tier 4)', () {
    test('a completed or cancelled trip is never active', () {
      for (final s in [TripStatus.completed, TripStatus.cancelled]) {
        expect(TripModel(id: 1, status: s).isActiveOnServer, isFalse);
        expect(
          TripModel(id: 1, status: s, serverActive: true).isActiveOnServer,
          isFalse,
        );
      }
    });

    test('is_active decides; an older server is read from the status', () {
      expect(
        TripModel.fromJson({
          'id': 138,
          'status': 'completed',
          'is_active': false,
          'recovery': 'recently_completed',
        }).isActiveOnServer,
        isFalse,
      );
      expect(
        TripModel.fromJson({'id': 2, 'status': 'in_progress', 'is_active': false})
            .isActiveOnServer,
        isFalse,
      );
      expect(
        TripModel.fromJson({'id': 3, 'status': 'in_progress'}).isActiveOnServer,
        isTrue,
      );
    });

    test('the trip detail carries cancelled_by', () {
      final t = TripModel.fromJson(
          {'id': 4, 'status': 'cancelled', 'cancelled_by': 'driver'});
      expect(CancelActor.fromServer(t.cancelledBy), CancelActor.you);
    });
  });

  test('clearing local storage keeps the appearance choice', () async {
    SharedPreferences.setMockInitialValues({
      'driver_appearance_mode_v1': 'light',
      'active_trip_id': '9',
    });
    await LocalStorageService.init();
    await LocalStorageService.clearAll();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('driver_appearance_mode_v1'), 'light');
    expect(prefs.getString('active_trip_id'), isNull);
  });
}
