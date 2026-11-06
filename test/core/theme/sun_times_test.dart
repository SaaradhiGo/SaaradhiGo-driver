import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/theme/sun_times.dart';

/// Known values (published almanac times, standard refraction), local time.
/// The NOAA calculation agrees with them to about a minute; allow three.
void main() {
  const tolerance = Duration(minutes: 3);
  const ist = Duration(hours: 5, minutes: 30);
  const bst = Duration(hours: 1);

  void near(DateTime? actualUtc, DateTime expectedLocal, Duration offset) {
    expect(actualUtc, isNotNull);
    final local = actualUtc!.add(offset);
    final expected = DateTime.utc(
      expectedLocal.year,
      expectedLocal.month,
      expectedLocal.day,
      expectedLocal.hour,
      expectedLocal.minute,
    );
    final diff = local.difference(expected).abs();
    expect(
      diff <= tolerance,
      isTrue,
      reason:
          'got ${local.toIso8601String()}, want ${expected.toIso8601String()}',
    );
  }

  group('Hyderabad 17.385N 78.4867E (IST)', () {
    const lat = 17.385, lng = 78.4867;

    test('June solstice: about 05:43 and 18:52', () {
      final t = computeSunTimes(DateTime(2026, 6, 21), lat, lng);
      near(t.sunrise, DateTime(2026, 6, 21, 5, 43), ist);
      near(t.sunset, DateTime(2026, 6, 21, 18, 52), ist);
    });

    test('December solstice: about 06:40 and 17:46', () {
      final t = computeSunTimes(DateTime(2026, 12, 21), lat, lng);
      near(t.sunrise, DateTime(2026, 12, 21, 6, 40), ist);
      near(t.sunset, DateTime(2026, 12, 21, 17, 46), ist);
    });

    test('daytime at 12:00 IST, night at 21:00 IST', () {
      expect(isDaytimeAt(DateTime.utc(2026, 11, 5, 6, 30), lat, lng), isTrue);
      expect(isDaytimeAt(DateTime.utc(2026, 11, 5, 15, 30), lat, lng), isFalse);
      // 05:00 IST, before sunrise.
      expect(isDaytimeAt(DateTime.utc(2026, 11, 4, 23, 30), lat, lng), isFalse);
    });
  });

  test('London 51.5074N 0.1278W, June solstice: about 04:43 and 21:21 BST', () {
    final t = computeSunTimes(DateTime(2026, 6, 21), 51.5074, -0.1278);
    near(t.sunrise, DateTime(2026, 6, 21, 4, 43), bst);
    near(t.sunset, DateTime(2026, 6, 21, 21, 21), bst);
  });

  test('inside the Arctic circle: midnight sun and polar night', () {
    final summer = computeSunTimes(DateTime(2026, 6, 21), 69.65, 18.96);
    expect(summer.polar, PolarDay.midnightSun);
    expect(summer.isDaylight(DateTime.utc(2026, 6, 21, 23)), isTrue);
    final winter = computeSunTimes(DateTime(2026, 12, 21), 69.65, 18.96);
    expect(winter.polar, PolarDay.polarNight);
    expect(winter.isDaylight(DateTime.utc(2026, 12, 21, 11)), isFalse);
  });

  test('clock fallback: day is 06:00 to 18:00', () {
    expect(isDaytimeByClock(DateTime(2026, 1, 1, 5, 59)), isFalse);
    expect(isDaytimeByClock(DateTime(2026, 1, 1, 6)), isTrue);
    expect(isDaytimeByClock(DateTime(2026, 1, 1, 17, 59)), isTrue);
    expect(isDaytimeByClock(DateTime(2026, 1, 1, 18)), isFalse);
  });
}
