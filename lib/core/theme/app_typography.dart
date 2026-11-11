import 'package:flutter/material.dart';

import '../../ui/sg_text.dart';

/// The older screens' type names, each on one of the five sizes in SgText
/// (Inter 400/600). Getters, because size class and language change at
/// runtime. Colourless, so the surrounding theme colours them.
class AppTypography {
  AppTypography._();

  static TextStyle _plain(TextStyle s, {bool figures = false}) => TextStyle(
    fontFamily: s.fontFamily,
    fontFamilyFallback: s.fontFamilyFallback,
    fontSize: s.fontSize,
    height: s.height,
    fontWeight: s.fontWeight,
    letterSpacing: s.letterSpacing,
    fontFeatures: figures ? const [FontFeature.tabularFigures()] : null,
  );

  static TextStyle get displayLg => _plain(SgText.heading);
  static TextStyle get headlineLgMobile => _plain(SgText.heading);
  static TextStyle get headlineMd => _plain(SgText.heading);
  static TextStyle get headlineSm => _plain(SgText.title);
  static TextStyle get bodyLg => _plain(SgText.body);
  static TextStyle get bodyMd => _plain(SgText.body);

  /// Small 600 label; screens that upper-case it use SgText.eyebrow.
  static TextStyle get labelCaps => _plain(SgText.label);

  /// Numbers: Inter 600 with tabular figures (no monospace family).
  static TextStyle get dataMono =>
      _plain(SgText.body, figures: true).copyWith(fontWeight: FontWeight.w600);
}
