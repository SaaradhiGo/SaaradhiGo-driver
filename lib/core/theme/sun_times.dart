/// Sunrise and sunset on the device, from the date and a coordinate: the NOAA
/// solar calculation (the algorithm behind NOAA's solar calculator
/// spreadsheet), no network. Accurate to about a minute between the polar
/// circles, which is far more than a day/night theme switch needs.
library;

import 'dart:math' as math;

/// Sunrise and sunset for one day at one place, in UTC.
class SunTimes {
  const SunTimes({this.sunrise, this.sunset, this.polar});

  /// Null on a day the sun does not rise or does not set.
  final DateTime? sunrise;
  final DateTime? sunset;

  /// Set when the sun never crosses the horizon that day:
  /// [PolarDay.midnightSun] (up all day) or [PolarDay.polarNight].
  final PolarDay? polar;

  /// Whether [instant] falls between sunrise and sunset.
  bool isDaylight(DateTime instant) {
    if (polar == PolarDay.midnightSun) return true;
    if (polar == PolarDay.polarNight) return false;
    final t = instant.toUtc();
    return !t.isBefore(sunrise!) && t.isBefore(sunset!);
  }
}

enum PolarDay { midnightSun, polarNight }

double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;

/// Sunrise and sunset for the civil day [date] (its year, month and day are
/// used as a UTC date) at [latitude], [longitude] (degrees, east positive).
///
/// The zenith is 90.833 degrees: the sun's upper limb on the horizon with
/// standard refraction, the definition published sunrise times use.
SunTimes computeSunTimes(DateTime date, double latitude, double longitude) {
  final noonUtc = DateTime.utc(date.year, date.month, date.day, 12);
  // Julian day at 12:00 UTC, refined with the local solar noon estimate.
  final jd = noonUtc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  final jdLocalNoon = jd - longitude / 360.0;

  double eqTimeMinutes(double jdx) => _solar(jdx).eqTime;

  // Solar noon (minutes after 00:00 UTC), with one refinement pass.
  var noonMin = 720 - 4 * longitude - eqTimeMinutes(jdLocalNoon);
  noonMin = 720 - 4 * longitude - eqTimeMinutes(jd - 0.5 + noonMin / 1440);

  final s = _solar(jd - 0.5 + noonMin / 1440);
  final lat = _rad(latitude);
  final cosH =
      math.cos(_rad(90.833)) / (math.cos(lat) * math.cos(s.decl)) -
      math.tan(lat) * math.tan(s.decl);
  if (cosH > 1) return const SunTimes(polar: PolarDay.polarNight);
  if (cosH < -1) return const SunTimes(polar: PolarDay.midnightSun);

  DateTime event(bool rising) {
    // Iterate once at the event time itself for a sharper answer.
    var minutes = noonMin + (rising ? -1 : 1) * 4 * _deg(math.acos(cosH));
    final e = _solar(jd - 0.5 + minutes / 1440);
    final c =
        math.cos(_rad(90.833)) / (math.cos(lat) * math.cos(e.decl)) -
        math.tan(lat) * math.tan(e.decl);
    final h = _deg(math.acos(c.clamp(-1.0, 1.0)));
    minutes = 720 - 4 * (longitude + (rising ? h : -h)) - e.eqTime;
    final base = DateTime.utc(date.year, date.month, date.day);
    return base.add(Duration(milliseconds: (minutes * 60000).round()));
  }

  return SunTimes(sunrise: event(true), sunset: event(false));
}

class _Solar {
  const _Solar(this.decl, this.eqTime);

  /// Declination, radians.
  final double decl;

  /// Equation of time, minutes.
  final double eqTime;
}

_Solar _solar(double jd) {
  final t = (jd - 2451545.0) / 36525.0;
  final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360;
  final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  final mr = _rad(m);
  final c =
      math.sin(mr) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
      math.sin(2 * mr) * (0.019993 - 0.000101 * t) +
      math.sin(3 * mr) * 0.000289;
  final trueLong = l0 + c;
  final omega = 125.04 - 1934.136 * t;
  final appLong = trueLong - 0.00569 - 0.00478 * math.sin(_rad(omega));
  final seconds = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813));
  final obliq0 = 23 + (26 + seconds / 60) / 60;
  final obliq = obliq0 + 0.00256 * math.cos(_rad(omega));
  final decl = math.asin(math.sin(_rad(obliq)) * math.sin(_rad(appLong)));
  final y = math.pow(math.tan(_rad(obliq) / 2), 2).toDouble();
  final l0r = _rad(l0);
  final eq =
      y * math.sin(2 * l0r) -
      2 * e * math.sin(mr) +
      4 * e * y * math.sin(mr) * math.cos(2 * l0r) -
      0.5 * y * y * math.sin(4 * l0r) -
      1.25 * e * e * math.sin(2 * mr);
  return _Solar(decl, 4 * _deg(eq));
}

/// Whether it is daytime at [now] (any time zone) at the given place.
///
/// The sun times are computed for the place's own solar date (UTC shifted by
/// the longitude), so a place far east or west of Greenwich gets its own day,
/// not its neighbour's.
bool isDaytimeAt(DateTime now, double latitude, double longitude) {
  final utc = now.toUtc();
  // Local solar date: shift UTC by the longitude (15 degrees an hour).
  final solarLocal = utc.add(Duration(minutes: (longitude * 4).round()));
  final times = computeSunTimes(solarLocal, latitude, longitude);
  return times.isDaylight(utc);
}

/// The fallback when there is no coordinate at all: day from 06:00 to 18:00
/// on the device clock.
bool isDaytimeByClock(DateTime localNow) =>
    localNow.hour >= 6 && localNow.hour < 18;
