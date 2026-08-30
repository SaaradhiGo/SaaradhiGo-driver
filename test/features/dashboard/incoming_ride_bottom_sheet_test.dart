import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/dashboard/data/data_sources/driver_location_consumer.dart';
import 'package:saaradhigo_driver/features/dashboard/presentation/widgets/incoming_ride_bottom_sheet.dart';

void main() {
  testWidgets(
    'IncomingRideBottomSheet renders details and handles accept/decline',
    (tester) async {
      bool accepted = false;
      bool declined = false;

      final request = DriverLocationRideRequest(const <String, dynamic>{
        'type': 'ride_request',
        'trip_id': 19,
        'rider_name': 'Raja Kumar',
        'pickup_address': 'Ameerpet Metro',
        'destination_address': 'Hitech City',
        'estimated_fare': '245.50',
        'distance_km': 10.5,
        'duration_min': 25.0,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingRideBottomSheet(
              request: request,
              onAccept: () => accepted = true,
              onDecline: () => declined = true,
              timeoutSeconds: 20,
            ),
          ),
        ),
      );

      expect(find.text('New Ride Request'), findsOneWidget);
      expect(find.text('Raja Kumar'), findsOneWidget);
      expect(find.text('Ameerpet Metro'), findsOneWidget);
      expect(find.text('Hitech City'), findsOneWidget);
      expect(find.text('₹245.50'), findsOneWidget);

      await tester.tap(find.text('ACCEPT RIDE'));
      await tester.pump();
      expect(accepted, isTrue);

      await tester.tap(find.text('DECLINE'));
      await tester.pump();
      expect(declined, isTrue);
    },
  );
}
