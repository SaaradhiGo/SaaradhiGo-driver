import 'package:flutter/material.dart';

/// The older screens' type scale, in Manrope (bundled) since group F.
class AppTypography {
  AppTypography._();

  static TextStyle _m(
    double size,
    double line,
    FontWeight w, {
    double spacing = 0,
    bool figures = false,
  }) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    height: line / size,
    fontWeight: w,
    fontVariations: [FontVariation('wght', w.value.toDouble())],
    letterSpacing: spacing,
    fontFeatures: figures ? const [FontFeature.tabularFigures()] : null,
  );

  static TextStyle displayLg = _m(32, 40, FontWeight.w700, spacing: -0.3);
  static TextStyle headlineLgMobile = _m(28, 34, FontWeight.w700);
  static TextStyle headlineMd = _m(24, 32, FontWeight.w700);
  static TextStyle headlineSm = _m(20, 28, FontWeight.w700);
  static TextStyle bodyLg = _m(17, 26, FontWeight.w500);
  static TextStyle bodyMd = _m(15, 22, FontWeight.w500);
  static TextStyle labelCaps = _m(12, 16, FontWeight.w700, spacing: 0.4);
  static TextStyle dataMono = _m(15, 20, FontWeight.w700, figures: true);
}
