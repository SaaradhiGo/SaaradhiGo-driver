import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/utils/formatters.dart';
import 'package:saaradhigo_driver/features/dispatch/domain/ride_offer.dart';
import 'package:saaradhigo_driver/features/earnings/domain/earnings.dart';
import 'package:saaradhigo_driver/features/profile/domain/driver_profile.dart';
import 'package:saaradhigo_driver/features/trip/domain/trip.dart';
import 'package:saaradhigo_driver/features/withdrawals/domain/withdrawal.dart';

import 'helpers/fakes.dart';

void main() {
  group('Trip parsing', () {
    test('reads the shape /ride/active/ returns', () {
      final trip = Trip.fromJson(const {
        'trip_id': 101,
        'status': 'in_progress',
        'rider_name': 'Raja Kumar',
        'pickup_lat': '17.3850000',
        'pickup_long': '78.4867000',
        'estimated_fare': '245.50',
        'payment_method': 'cash',
      });

      expect(trip.id, 101);
      expect(trip.status, TripStatus.inProgress);
      expect(trip.pickupLat, closeTo(17.385, 0.0001));
      // The consumer emits pickup_long, the WS offer emits pickup_lng.
      expect(trip.pickupLng, closeTo(78.4867, 0.0001));
      expect(trip.isCash, isTrue);
    });

    test('maps the server WS status vocabulary onto the enum', () {
      expect(TripStatus.parse('accept'), TripStatus.accepted);
      expect(TripStatus.parse('start'), TripStatus.inProgress);
      expect(TripStatus.parse('complete'), TripStatus.completed);
      expect(TripStatus.parse('cancel'), TripStatus.cancelled);
      expect(TripStatus.parse('nonsense'), TripStatus.unknown);
    });

    test('merge keeps fields a partial WS frame does not carry', () {
      final trip = buildTrip(status: TripStatus.accepted);

      final merged = trip.merge(const {'status': 'reached'});

      expect(merged.status, TripStatus.reached);
      expect(merged.riderName, 'Raja Kumar',
          reason: 'a status-only frame must not blank the rider');
      expect(merged.pickupAddress, 'Ameerpet Metro');
    });

    test('fareToCollect prefers the final fare over the estimate', () {
      final trip = buildTrip().copyWith(finalFare: '300.00');
      expect(trip.fareToCollect, '300.00');
      expect(buildTrip().fareToCollect, '245.50');
    });
  });

  group('DriverProfile gating', () {
    test('an approved driver with a vehicle may go online', () {
      expect(buildProfile().canGoOnline, isTrue);
      expect(buildProfile().kycState, KycState.approved);
    });

    test('an unapproved driver is blocked with an explanation', () {
      final profile = buildProfile(approved: false);
      expect(profile.canGoOnline, isFalse);
      expect(profile.blockingReason, contains('verified'));
      expect(profile.kycState, KycState.pendingReview);
    });

    test('missing documents is distinct from awaiting review', () {
      final profile = buildProfile(approved: false, withVehicle: false);
      expect(profile.kycState, KycState.documentsMissing);
    });

    test('a blocked account cannot go online', () {
      final profile = buildProfile(status: 'blocked');
      expect(profile.isBlocked, isTrue);
      expect(profile.canGoOnline, isFalse);
      expect(profile.blockingReason, contains('blocked'));
    });

    test('a fatigue lockout blocks going online until it expires', () {
      final locked = buildProfile(
        lockoutUntil: DateTime.now().add(const Duration(minutes: 40)),
      );
      expect(locked.isLockedOut, isTrue);
      expect(locked.canGoOnline, isFalse);
      expect(locked.lockoutRemaining!.inMinutes, greaterThan(30));

      final expired = buildProfile(
        lockoutUntil: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(expired.isLockedOut, isFalse);
      expect(expired.canGoOnline, isTrue);
    });
  });

  group('Vehicle credential expiry', () {
    test('surfaces credentials expiring inside the window, soonest first', () {
      final vehicle = Vehicle(
        id: 1,
        vehicleNumber: 'TS09AB1234',
        insuranceExpiry: DateTime.now().add(const Duration(days: 25)),
        permitExpiry: DateTime.now().add(const Duration(days: 5)),
        fitnessExpiry: DateTime.now().add(const Duration(days: 300)),
      );

      final expiring = vehicle.expiringWithin(30);

      expect(expiring, hasLength(2));
      expect(expiring.first.label, 'Permit',
          reason: 'the most urgent renewal must lead');
    });
  });

  group('RideOffer countdown', () {
    test('counts down from the configured timeout', () {
      final offer = RideOffer.fromEvent(const {
        'trip_id': 101,
        'estimated_fare': '245.50',
        'pickup_lat': '17.385',
      });

      expect(offer.tripId, 101);
      expect(offer.isExpired, isFalse);
      expect(offer.progress, closeTo(1.0, 0.05));
      expect(offer.pickupLat, closeTo(17.385, 0.001));
    });

    test('expires once the wall-clock window has passed', () {
      final stale = RideOffer(
        tripId: 5,
        receivedAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      expect(stale.isExpired, isTrue);
      expect(stale.remaining, Duration.zero);
      expect(stale.progress, 0);
    });
  });

  group('EarningsSummary', () {
    test('a negative balance means the driver owes commission', () {
      final summary = EarningsSummary.fromJson(const {
        'total_earned': '5000.00',
        'total_commission': '900.00',
        'wallet_balance': '-420.00',
        'today_earned': '780.00',
        'today_trips': 6,
        'total_trips': 40,
        'commission_percent': 18,
      });

      expect(summary.owesPlatform, isTrue);
      expect(summary.netEarned, 4100.00);
      expect(summary.todayTrips, 6);
    });
  });

  group('EarningsPeriod rollup', () {
    test('sums only entries inside the window and separates cash', () {
      final now = DateTime.now();
      final entries = [
        EarningEntry(id: 1, amount: 100, method: 'cash', createdAt: now),
        EarningEntry(id: 2, amount: 200, method: 'online', createdAt: now),
        EarningEntry(
          id: 3,
          amount: 999,
          method: 'cash',
          createdAt: now.subtract(const Duration(days: 40)),
        ),
      ];

      final period = EarningsPeriod.from(
        'This month',
        entries,
        DateTime(now.year, now.month),
      );

      expect(period.gross, 300);
      expect(period.trips, 2);
      expect(period.cashCollected, 100);
    });
  });

  group('WithdrawalBalance', () {
    test('rejects amounts under the minimum or over the balance', () {
      const balance = WithdrawalBalance(
        availableBalance: 2000,
        blocked: false,
        minimumWithdrawal: 500,
      );

      expect(balance.canWithdraw(1000), isTrue);
      expect(balance.canWithdraw(200), isFalse);
      expect(balance.canWithdraw(5000), isFalse);
    });

    test('a cooldown blocks any amount', () {
      const balance = WithdrawalBalance(
        availableBalance: 2000,
        blocked: true,
        minimumWithdrawal: 500,
      );
      expect(balance.canWithdraw(1000), isFalse);
    });
  });

  group('WithdrawalRequest', () {
    test('explains each server status in the driver\'s terms', () {
      expect(
        const WithdrawalRequest(id: 1, amount: 500, status: 'processing')
            .explanation,
        contains('bank'),
      );
      expect(
        const WithdrawalRequest(id: 1, amount: 500, status: 'failed')
            .explanation,
        contains('back in your balance'),
      );
    });
  });

  group('Formatters', () {
    test('formats money in the Indian numbering system', () {
      // 1,23,456 — lakh grouping, not 123,456.
      expect(Fmt.money('123456'), contains('1,23,456'));
      expect(Fmt.money('245.50'), contains('245.50'));
    });

    test('parses API decimal strings without losing precision', () {
      expect(Fmt.toAmount('245.50'), 245.50);
      expect(Fmt.toAmount(null), 0);
      expect(Fmt.toAmount('not-a-number'), 0);
    });

    test('formats short and long durations differently', () {
      expect(Fmt.duration(const Duration(seconds: 45)), '45s');
      expect(Fmt.duration(const Duration(minutes: 12)), '12 min');
      expect(Fmt.duration(const Duration(hours: 2, minutes: 5)), '2h 05m');
    });
  });
}
