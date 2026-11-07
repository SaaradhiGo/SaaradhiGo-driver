import 'package:flutter/material.dart';

import '../../ui/sg_text.dart';

/// The older screens' type names, in Noto Sans (bundled) for the active locale.
/// Getters, because the family follows the app language at runtime.
class AppTypography {
  AppTypography._();

  static TextStyle _m(
    double size,
    double line,
    FontWeight w, {
    bool figures = false,
  }) => TextStyle(
    fontFamily: SgText.family,
    fontFamilyFallback: SgText.fallback,
    fontSize: SgText.size(size),
    height: line / size,
    fontWeight: w,
    fontVariations: [FontVariation('wght', w.value.toDouble())],
    letterSpacing: 0,
    fontFeatures: figures ? const [FontFeature.tabularFigures()] : null,
  );

  // The older names on the Tier 1 scale (SgText): same sizes, same factor.
  static TextStyle get displayLg => _m(24, 30, FontWeight.w600);
  static TextStyle get headlineLgMobile => _m(24, 30, FontWeight.w600);
  static TextStyle get headlineMd => _m(24, 30, FontWeight.w600);
  static TextStyle get headlineSm => _m(18, 24, FontWeight.w600);
  static TextStyle get bodyLg => _m(16, 24, FontWeight.w400);
  static TextStyle get bodyMd => _m(16, 24, FontWeight.w400);
  static TextStyle get labelCaps => _m(13, 18, FontWeight.w600);

  /// Numbers: Noto Sans with tabular figures (no monospace family).
  static TextStyle get dataMono => _m(16, 22, FontWeight.w600, figures: true);
}
