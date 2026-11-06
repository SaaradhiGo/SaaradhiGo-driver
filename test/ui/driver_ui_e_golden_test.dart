// Goldens at 390x844 logical. Regenerate with:
//   flutter test --update-goldens test/ui/driver_ui_e_golden_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/ui/driver_earnings_view.dart';
import 'package:saaradhigo_driver/ui/driver_f_logic.dart';
import 'package:saaradhigo_driver/ui/driver_trip_views.dart';

import '../support/driver_ui_fixtures.dart';

/// Same 1% tolerance as group D: Windows-made goldens, Linux CI.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
        imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= 0.01) return true;
    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}

Future<void> shoot(WidgetTester tester, Widget frame, String name) async {
  setPhoneSurface(tester);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(sgApp(frame));
  await tester.pump(const Duration(milliseconds: 200));
  await expectLater(
      find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  setUpAll(() async {
    goldenFileComparator = _TolerantComparator(
        (goldenFileComparator as LocalFileComparator)
            .basedir
            .resolve('driver_ui_e_golden_test.dart'));
    await loadSgFonts();
  });

  testWidgets('to pickup', (t) => shoot(t, toPickupFrame(), 'to_pickup'));

  testWidgets('PIN check', (t) async {
    final c = TextEditingController(text: '418');
    addTearDown(c.dispose);
    await shoot(
      t,
      PinCheckView(
        controller: c,
        riderName: 'Raja Kumar',
        riderRating: 4.8,
        pickupAddress: 'Ameerpet Metro Station, Gate 2',
        topActions: sosStandIn(),
        onMessage: () {},
        onStart: () {},
        onCancel: () {},
      ),
      'pin_check',
    );
  });

  testWidgets('in trip', (t) => shoot(t, inTripFrame(), 'in_trip'));

  testWidgets('in trip at night',
      (t) => shoot(t, inTripFrame(night: true), 'in_trip_night'));

  testWidgets('earnings', (t) async {
    await shoot(
      t,
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EarningsNoirPanel(
            periodLabel: 'Today',
            trips: 3,
            amount: '₹364',
            isNet: true,
            commission: '₹64',
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
      ),
      'earnings_t3',
    );
  });


  testWidgets('complete, collect cash',
      (t) => shoot(t, completeFrame(), 'complete_cash'));

  testWidgets('complete, paid online',
      (t) => shoot(t, completeFrame(cash: false), 'complete_paid'));
}
