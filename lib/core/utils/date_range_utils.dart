import 'package:flutter/material.dart';

/// Normalizes a [DateTimeRange] so `start` lands on 00:00:00.000 of the start
/// day and `end` lands on 23:59:59.999 of the end day.
///
/// `showDateRangePicker` returns a range whose `end` is 00:00:00 of the chosen
/// end day; normalizing here guarantees trips on the selected end day are
/// included when the range is used for filtering or sent to the backend.
DateTimeRange normalizeDateRange(DateTimeRange range) {
  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final end = DateTime(
    range.end.year,
    range.end.month,
    range.end.day,
    23,
    59,
    59,
    999,
  );
  return DateTimeRange(start: start, end: end);
}

/// Returns `true` when the ISO-8601 trip instant [isoCreatedAt] belongs to
/// [range] (inclusive bounds, compared in local time).
///
/// - A `null` [range] (All Time) keeps every trip, including unparseable dates.
/// - A `null` or unparseable [isoCreatedAt] is excluded whenever a range is
///   active — and never throws.
/// - Timezone-aware timestamps are converted with `.toLocal()` before the
///   comparison so device-local day windows line up with the parsed instant.
bool tripCreatedAtWithin(String? isoCreatedAt, DateTimeRange? range) {
  if (range == null) return true;
  if (isoCreatedAt == null) return false;
  final parsed = DateTime.tryParse(isoCreatedAt);
  if (parsed == null) return false;
  final local = parsed.toLocal();
  return !local.isBefore(range.start) && !local.isAfter(range.end);
}