// The Earnings tabs show their own period, never the all-time totals.
//
// Found on the QA build (2026-11-06): the Today tab read "Today · 6 trips
// ₹1,065", the driver's all-time totals, while Home said 4 trips today.
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/ui/driver_f_logic.dart';

DailyEarning _d(String date, int trips, double net, {double? gross, double? commission}) =>
    DailyEarning(
      date: DateTime.parse(date),
      trips: trips,
      net: net,
      gross: gross,
      commission: commission,
    );

void main() {
  // Friday 2026-11-06 is "today": the series' last day.
  final days = [
    _d('2026-10-31', 1, 50, gross: 60, commission: 10), // Saturday, last month
    _d('2026-11-01', 0, 0, gross: 0, commission: 0), // Sunday
    _d('2026-11-02', 0, 0, gross: 0, commission: 0), // Monday
    _d('2026-11-05', 2, 614.87, gross: 723.38, commission: 108.51), // Thursday
    _d('2026-11-06', 4, 450.43, gross: 529.92, commission: 79.49), // Friday
  ];

  test('Today is the summary\'s own today figures', () {
    final f = periodFigures(0,
        todayTrips: 4,
        todayNet: '450.43',
        todayCommission: '79.49',
        todayGross: '529.92',
        days: days)!;
    expect(f.trips, 4);
    expect(f.net, '450.43');
    expect(f.commission, '79.49');
  });

  test('This week sums Monday to today from the daily series', () {
    final f = periodFigures(1,
        todayTrips: 4, todayNet: null, todayCommission: null, todayGross: null, days: days)!;
    expect(f.trips, 6);
    expect(f.net, '1065.30');
    expect(f.gross, '1253.30');
    expect(f.commission, '188.00');
  });

  test('This month leaves out last month', () {
    final f = periodFigures(2,
        todayTrips: 4, todayNet: null, todayCommission: null, todayGross: null, days: days)!;
    expect(f.trips, 6);
    expect(f.net, '1065.30');
  });

  test('No series: week and month show nothing rather than all-time', () {
    expect(
        periodFigures(1,
            todayTrips: 4, todayNet: null, todayCommission: null, todayGross: null, days: null),
        isNull);
    expect(
        periodFigures(0,
            todayTrips: null, todayNet: null, todayCommission: null, todayGross: null, days: days),
        isNull);
  });

  test('A day without gross leaves the week\'s gross unknown, not short', () {
    final f = periodFigures(1,
        todayTrips: 1,
        todayNet: null,
        todayCommission: null,
        todayGross: null,
        days: [_d('2026-11-06', 1, 85)])!;
    expect(f.net, '85.00');
    expect(f.gross, isNull);
  });
}
