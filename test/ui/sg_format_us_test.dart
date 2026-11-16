import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip_history/presentation/widgets/trip_history_card.dart';
import 'package:saaradhigo_driver/ui/driver_trip_views.dart';
import 'package:saaradhigo_driver/ui/sg_format.dart';

/// US parity (15 Nov): a US trip reads miles and a month-first date in the
/// trip's own time zone; an Indian trip stays km, day-first, Asia/Kolkata.
void main() {
  setUpAll(() => initializeDateFormatting('en'));
  final now = DateTime(2026, 11, 15);

  test('distance by the trip currency', () {
    expect(sgDistance(10, currency: 'USD'), '6.2 mi');
    expect(sgDistance(10, currency: 'INR'), '10.0 km');
    expect(sgDistanceUnit(currency: 'USD'), 'mi');
    expect(distanceTimeLine(8.4, 20, currency: 'USD'), '5.2 mi · 20 min');
    expect(distanceTimeLine(8.4, 20, currency: 'INR'), '8.4 km · 20 min');
  });

  test('a US trip: month first, in the trip time zone', () {
    expect(
      sgTripDayTime(
        '2026-11-15T00:55:00Z',
        currency: 'USD',
        timezone: 'America/Boise',
        now: now,
        languageCode: 'en',
      ),
      'Sat, Nov 14, 5:55 PM',
    );
  });

  test('an Indian trip: day first, in Asia/Kolkata', () {
    expect(
      sgTripDayTime(
        '2026-11-14T12:00:00Z',
        currency: 'INR',
        now: now,
        languageCode: 'en',
      ),
      'Sat, 14 Nov · 5:30 pm',
    );
  });

  test('a US day and an unknown zone', () {
    expect(
      sgDay(
        DateTime(2026, 11, 14),
        now: now,
        languageCode: 'en',
        country: 'US',
      ),
      'Sat, Nov 14',
    );
    expect(
      sgInZone(DateTime.utc(2026), 'Not/AZone'),
      DateTime.utc(2026).toLocal(),
    );
  });

  testWidgets('the trip history card reads miles and the US date', (t) async {
    const trip = TripModel(
      id: 1,
      status: TripStatus.completed,
      distanceKm: 10,
      durationMin: 18,
      createdAt: '2026-11-15T00:55:00Z',
      currency: 'USD',
      timezone: 'America/Boise',
    );
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripHistoryCard(trip: trip, onTap: () {}),
        ),
      ),
    );
    expect(find.text('6.2 mi'), findsOneWidget);
    expect(find.textContaining('km'), findsNothing);
    expect(find.textContaining('Nov 14'), findsOneWidget);
  });
}
