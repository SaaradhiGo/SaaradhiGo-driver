import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/utils/date_range_utils.dart';

void main() {
  final pickerRange = DateTimeRange(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 4), // showDateRangePicker returns end at 00:00:00
  );
  final normalizedRange = DateTimeRange(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 4, 23, 59, 59, 999),
  );

  group('normalizeDateRange', () {
    test('floors start to 00:00:00.000 of the start day', () {
      final normalized = normalizeDateRange(
        DateTimeRange(
          start: DateTime(2026, 9, 1, 14, 30, 5, 123),
          end: DateTime(2026, 9, 4),
        ),
      );
      expect(normalized.start.hour, equals(0));
      expect(normalized.start.minute, equals(0));
      expect(normalized.start.second, equals(0));
      expect(normalized.start.millisecond, equals(0));
    });

    test('raises end to 23:59:59.999 of the end day', () {
      final normalized = normalizeDateRange(pickerRange);
      expect(normalized.end.hour, equals(23));
      expect(normalized.end.minute, equals(59));
      expect(normalized.end.second, equals(59));
      expect(normalized.end.millisecond, equals(999));
      expect(normalized.end.day, equals(4));
    });
  });

  group('tripCreatedAtWithin', () {
    test('null range keeps every trip, including unparseable dates', () {
      expect(tripCreatedAtWithin(null, null), isTrue);
      expect(tripCreatedAtWithin('not-a-date', null), isTrue);
      expect(
        tripCreatedAtWithin('2026-09-01T00:00:00', null),
        isTrue,
      );
    });

    test('null or unparseable createdAt excluded when a range is active', () {
      expect(tripCreatedAtWithin(null, normalizedRange), isFalse);
      expect(tripCreatedAtWithin('not-a-date', normalizedRange), isFalse);
    });

    test('inclusive bounds: instants at start and end are inside', () {
      expect(
        tripCreatedAtWithin('2026-09-01T00:00:00', normalizedRange),
        isTrue,
      );
      expect(
        tripCreatedAtWithin('2026-09-04T23:59:59.999', normalizedRange),
        isTrue,
      );
    });

    test('instants outside the range are excluded', () {
      expect(
        tripCreatedAtWithin('2026-09-05T00:00:00', normalizedRange),
        isFalse,
      );
      expect(
        tripCreatedAtWithin('2026-08-31T23:59:59', normalizedRange),
        isFalse,
      );
    });

    test('timezone-aware instant is converted to local before comparing', () {
      // Serialize a local midday to its UTC form; parsing it back and
      // reapplying toLocal() must land inside the same local day window.
      final local = DateTime(2026, 9, 4, 12, 0, 0); // local midday
      final utcSerialized = local.toUtc().toIso8601String();
      expect(tripCreatedAtWithin(utcSerialized, normalizedRange), isTrue);
    });
  });
}