// WCAG 2.x contrast computed from the token values, both palettes. Fails CI
// when a token change makes a text pair unreadable (Tier 1 spec 1.1).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/ui/sg_tokens.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

/// Contrast of [fg] over [bg]; a translucent [fg] is composited first.
double contrast(Color fg, Color bg) {
  final f = Color.alphaBlend(fg, bg);
  final a = _luminance(f), b = _luminance(bg);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  for (final p in [SgPalette.dark, SgPalette.light]) {
    final name = p.isDark ? 'dark' : 'light';

    group('$name palette', () {
      final surfaces = {
        'bg-000': p.bg000,
        'bg-100': p.bg100,
        'bg-200': p.bg200,
      };
      final texts = {
        'ink': p.ink,
        'ink-muted': p.inkMuted,
        'ink-subtle': p.inkSubtle,
        'gold-text': p.goldText,
        'pickup': p.pickup,
        'success': p.success,
        'danger': p.danger,
      };

      for (final t in texts.entries) {
        for (final s in surfaces.entries) {
          test('${t.key} on ${s.key} >= 4.5:1', () {
            expect(contrast(t.value, s.value), greaterThanOrEqualTo(4.5));
          });
        }
      }

      test('on-gold on gold-500 >= 4.5:1', () {
        expect(contrast(p.onGold, p.gold500), greaterThanOrEqualTo(4.5));
      });

      test('on-danger on danger >= 4.5:1', () {
        expect(contrast(p.onDanger, p.danger), greaterThanOrEqualTo(4.5));
      });

      test('line-strong on bg-100 >= 3:1 (control edge)', () {
        expect(contrast(p.lineStrong, p.bg100), greaterThanOrEqualTo(3));
      });

      for (final c in SgVehicleClass.values) {
        test('${c.name} class colour on its tile >= 4.5:1', () {
          expect(
            contrast(c.colorIn(p), c.tileIn(p)),
            greaterThanOrEqualTo(4.5),
          );
        });
      }

      test('neutral (unknown class): ink on bg-300 >= 4.5:1', () {
        expect(contrast(p.ink, p.bg300), greaterThanOrEqualTo(4.5));
      });
    });
  }

  test('vehicle codes map to the shared class table', () {
    expect(SgVehicleClass.fromCode('bike'), SgVehicleClass.bike);
    expect(SgVehicleClass.fromCode('auto'), SgVehicleClass.auto);
    expect(SgVehicleClass.fromCode('hatchback'), SgVehicleClass.car);
    expect(SgVehicleClass.fromCode('mini'), SgVehicleClass.car);
    expect(SgVehicleClass.fromCode('sedan'), SgVehicleClass.comfort);
    expect(SgVehicleClass.fromCode('SUV'), SgVehicleClass.suv);
    expect(SgVehicleClass.fromCode('premium'), SgVehicleClass.premium);
    expect(SgVehicleClass.fromCode('black'), SgVehicleClass.premium);
    expect(SgVehicleClass.fromCode('luxury'), SgVehicleClass.premium);
    expect(SgVehicleClass.fromCode('helicopter'), isNull);
    expect(SgVehicleClass.fromCode(null), isNull);
  });
}
