import 'package:flutter/material.dart';

import '../../ui/sg_text.dart';

/// The older screens' type names, in Anek (bundled) for the active locale.
/// Getters, because the family follows the app language at runtime.
class AppTypography {
  AppTypography._();

  static TextStyle _m(
    double size,
    double line,
    FontWeight w, {
    double spacing = 0,
    bool figures = false,
  }) => TextStyle(
    fontFamily: SgText.family,
    fontFamilyFallback: SgText.fallback,
    fontSize: size,
    height: line / size,
    fontWeight: w,
    fontVariations: [FontVariation('wght', w.value.toDouble())],
    letterSpacing: spacing,
    fontFeatures: figures ? const [FontFeature.tabularFigures()] : null,
  );

  // Sizes unchanged from before Tier 1 so the older layouts hold; the
  // design-system scale lives in SgText.
  static TextStyle get displayLg => _m(32, 40, FontWeight.w700, spacing: -0.3);
  static TextStyle get headlineLgMobile => _m(28, 34, FontWeight.w700);
  static TextStyle get headlineMd => _m(24, 32, FontWeight.w700);
  static TextStyle get headlineSm => _m(20, 28, FontWeight.w700);
  static TextStyle get bodyLg => _m(17, 26, FontWeight.w500);
  static TextStyle get bodyMd => _m(15, 22, FontWeight.w500);
  static TextStyle get labelCaps => _m(12, 16, FontWeight.w700, spacing: 0.4);

  /// Numbers: Anek with tabular figures (no monospace family).
  static TextStyle get dataMono => _m(15, 20, FontWeight.w700, figures: true);
}
