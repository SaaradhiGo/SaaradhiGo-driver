import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/ui/driver_trip_views.dart';

import '../support/driver_ui_fixtures.dart';

/// The masked Call button (9 Nov): at pickup and during the trip, never a number.
void main() {
  setUpAll(loadSgFonts);

  testWidgets('to pickup: Call sits beside Message and calls through',
      (tester) async {
    var called = 0;
    await tester.pumpWidget(sgApp(Material(
      child: ToPickupSheet(
        riderName: 'Raja Kumar',
        pickupAddress: 'Ameerpet Metro Station',
        onMessage: () {},
        onCall: () => called++,
      ),
    )));
    expect(find.byKey(const Key('trip_call')), findsOneWidget);
    expect(find.byKey(const Key('trip_message')), findsOneWidget);
    await tester.tap(find.byKey(const Key('trip_call')));
    expect(called, 1);
    expect(find.textContaining(RegExp(r'\d{10}')), findsNothing);
  });

  testWidgets('no onCall, no button', (tester) async {
    await tester.pumpWidget(sgApp(const Material(
      child: ToPickupSheet(riderName: 'Raja', pickupAddress: 'A'),
    )));
    expect(find.byKey(const Key('trip_call')), findsNothing);
  });

  testWidgets('during the trip: Call on the sheet', (tester) async {
    var called = 0;
    await tester.pumpWidget(sgApp(Material(
      child: InTripSheet(
        destination: 'Hitech City, Hyderabad',
        riderName: 'Raja Kumar',
        onCall: () => called++,
      ),
    )));
    await tester.tap(find.byKey(const Key('trip_call')));
    expect(called, 1);
    expect(find.text('Call'), findsOneWidget);
  });
}
