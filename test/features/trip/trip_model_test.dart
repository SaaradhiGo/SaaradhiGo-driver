import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';

void main() {
  group('TripModel deserialization resilience', () {
    test(
      'parses Django REST Framework string Decimal values without throwing',
      () {
        final json = {
          'id': 101,
          'pickup_address': 'Ameerpet Metro Station',
          'destination_address': 'Hitech City Cyber Towers',
          'pickup_lat': '17.385000',
          'pickup_long': '78.486700',
          'destination_lat': '17.440000',
          'destination_long': '78.348000',
          'estimated_fare': '245.50',
          'final_fare': '245.50',
          'surge_multiplier': '1.00',
          'estimated_distance_km': '10.50',
          'actual_distance_km': '10.50',
          'estimated_duration_min': '25.00',
          'actual_duration_min': '24.00',
          'payment_method': 'cash',
          'payment_status': 'completed',
          'status': 'in_progress',
          'user': 'Raja Kumar',
          'driver_name': 'Driver Suresh',
        };

        final trip = TripModel.fromJson(json);

        expect(trip.id, equals(101));
        expect(trip.status, equals(TripStatus.inProgress));
        expect(trip.pickupLat, equals(17.385));
        expect(trip.pickupLng, equals(78.4867));
        expect(trip.destinationLat, equals(17.44));
        expect(trip.destinationLng, equals(78.348));
        expect(trip.distanceKm, equals(10.5));
        expect(trip.durationMin, equals(24.0));
        expect(trip.riderName, equals('Raja Kumar'));
        expect(trip.driverName, equals('Driver Suresh'));
      },
    );

    test('normalizes status string variants and DRF status_code values', () {
      expect(
        TripModel.fromJson({'id': 1, 'status': 'IN_PROGRESS'}).status,
        equals(TripStatus.inProgress),
      );
      expect(
        TripModel.fromJson({'id': 2, 'status': 'ACCEPTED'}).status,
        equals(TripStatus.accepted),
      );
      expect(
        TripModel.fromJson({'id': 3, 'status': 'accept'}).status,
        equals(TripStatus.accepted),
      );
      expect(
        TripModel.fromJson({'id': 4, 'status': 'start'}).status,
        equals(TripStatus.inProgress),
      );
      expect(
        TripModel.fromJson({'id': 5, 'status': 'reached'}).status,
        equals(TripStatus.reached),
      );
      expect(
        TripModel.fromJson({'id': 6, 'status': 'arrived'}).status,
        equals(TripStatus.reached),
      );
      expect(
        TripModel.fromJson({'id': 7, 'status': 'completed'}).status,
        equals(TripStatus.completed),
      );
      expect(
        TripModel.fromJson({'id': 8, 'status': 'cancelled'}).status,
        equals(TripStatus.cancelled),
      );
      expect(
        TripModel.fromJson({'id': 9, 'status': 'pending'}).status,
        equals(TripStatus.requested),
      );
      expect(
        TripModel.fromJson({
          'id': 10,
          'status_id': {'status_code': 'in_progress'},
        }).status,
        equals(TripStatus.inProgress),
      );
    });

    test('parses string IDs and nested map user correctly', () {
      final json = {
        'trip_id': '456',
        'rider_id': '12',
        'driver_id': '34',
        'status': 'accepted',
        'user': {'first_name': 'Priya', 'last_name': 'Sharma'},
      };

      final trip = TripModel.fromJson(json);

      expect(trip.id, equals(456));
      expect(trip.riderId, equals(12));
      expect(trip.driverId, equals(34));
      expect(trip.riderName, equals('Priya Sharma'));
    });

    test('handles fallback when coordinates or fields are null', () {
      final trip = TripModel.fromJson({'id': 789});

      expect(trip.id, equals(789));
      expect(trip.status, equals(TripStatus.requested));
      expect(trip.pickupLat, isNull);
      expect(trip.pickupLng, isNull);
      expect(trip.distanceKm, isNull);
      expect(trip.riderName, equals('Rider'));
    });
  });
}
