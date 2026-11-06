// The on-trip sheet shows what the driver keeps once the trip carries it.
//
// Found on QA trip 136 (2026-11-06): the sheet showed "₹102 Fare · Cash"
// because the trip payload had no earning. The backend now sends
// `driver_earning` (the settlement's own number) to the trip's driver.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/ui/driver_trip_views.dart';

import '../support/driver_ui_fixtures.dart';

void main() {
  testWidgets('with an earning: the earning, labelled You earn', (tester) async {
    await tester.pumpWidget(sgApp(const Material(
      child: InTripSheet(
        destination: 'Inorbit Mall, Hitech City',
        riderName: 'Aarav Sharma',
        fare: '₹102',
        earning: '₹86.70',
        payment: 'Cash',
      ),
    )));
    expect(find.byKey(const Key('trip_earning')), findsOneWidget);
    expect(find.text('₹86.70'), findsOneWidget);
    expect(find.textContaining('You earn'), findsOneWidget);
    expect(find.byKey(const Key('trip_fare')), findsNothing);
  });

  testWidgets('without one: the fare, labelled Fare', (tester) async {
    await tester.pumpWidget(sgApp(const Material(
      child: InTripSheet(
        destination: 'Inorbit Mall, Hitech City',
        riderName: 'Aarav Sharma',
        fare: '₹102',
        payment: 'Cash',
      ),
    )));
    expect(find.byKey(const Key('trip_fare')), findsOneWidget);
    expect(find.textContaining('Fare'), findsOneWidget);
  });
}
