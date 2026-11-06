/// Type styles (Tier 1): Anek for the interface, picked by the active locale
/// (AnekLatin / AnekTelugu / AnekDevanagari, the others as fallbacks), and
/// Cinzel 600 for the "Saaradhi Go" lettering beside the badge only.
///
/// Every style is a getter: colours come from the active palette and the
/// family from the active locale, both of which can change at runtime.
library;

import 'package:flutter/material.dart';

import 'sg_tokens.dart';

class SgText {
  SgText._();

  static const latin = 'AnekLatin';
  static const telugu = 'AnekTelugu';
  static const devanagari = 'AnekDevanagari';

  /// Brand lettering only. Never headings or body.
  static const brand = 'Cinzel';

  static String _languageCode = 'en';

  /// Set by the locale controller when the app language changes.
  static void useLanguage(String languageCode) => _languageCode = languageCode;

  /// The UI family for the active language.
  static String get family => familyFor(_languageCode);

  static String familyFor(String languageCode) => switch (languageCode) {
    'te' => telugu,
    'hi' => devanagari,
    _ => latin,
  };

  /// The other two Anek families, so mixed-script text (a Telugu street name
  /// in an English UI) still renders.
  static List<String> get fallback => fallbackFor(_languageCode);

  static List<String> fallbackFor(String languageCode) => [
    for (final f in const [latin, telugu, devanagari])
      if (f != familyFor(languageCode)) f,
  ];

  /// Kept for older call sites: the UI family.
  static String get sans => family;

  static TextStyle _anek(
    double size,
    double line,
    double weight, {
    Color? color,
    double spacing = 0,
    bool figures = false,
  }) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: size,
    height: line / size,
    fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
    fontVariations: [FontVariation('wght', weight)],
    letterSpacing: spacing,
    color: color ?? SgColors.ink,
    fontFeatures: figures ? const [FontFeature.tabularFigures()] : null,
  );

  /// 34/36, 800, -0.03em. One per screen.
  static TextStyle get display => _anek(34, 36, 800, spacing: -1.02);

  /// Older name for [display].
  static TextStyle get displayLg => display;

  static TextStyle get heading => _anek(26, 30, 800);
  static TextStyle get title => _anek(17, 22, 800);
  static TextStyle get body => _anek(16, 22, 500);

  /// Older name; the scale has one body size.
  static TextStyle get bodyLg => body;

  static TextStyle get caption => _anek(14, 20, 500, color: SgColors.inkMuted);

  /// 13/18, 700, 0.14em. Upper-case the string at the call site.
  static TextStyle get label =>
      _anek(13, 18, 700, color: SgColors.inkSubtle, spacing: 1.82);

  static TextStyle get fareXl => _anek(56, 56, 800, figures: true);
  static TextStyle get fare => _anek(22, 24, 800, figures: true);

  /// The driver's big earnings figure.
  static TextStyle get driverEarning => _anek(96, 92, 800, figures: true);

  static TextStyle get button =>
      _anek(16, 22, 700, color: SgColors.onGold, figures: true);

  /// "Saaradhi Go" beside the badge in headers: Cinzel 600, gold-text.
  static TextStyle brandLettering({double size = 18}) => TextStyle(
    fontFamily: brand,
    fontSize: size,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: SgColors.goldText,
  );
}

/// The app theme in the active palette. Kept for older call sites; the app
/// itself builds its theme with AppTheme.of (lib/core/theme/app_theme.dart).
ThemeData sgDarkTheme() => sgTheme(SgPalette.dark);

ThemeData sgTheme(SgPalette p) {
  final base = ThemeData(brightness: p.brightness, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: p.bg000,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: p.gold500,
          brightness: p.brightness,
        ).copyWith(
          primary: p.gold500,
          onPrimary: p.onGold,
          surface: p.bg100,
          onSurface: p.ink,
          error: p.danger,
          onError: p.onDanger,
        ),
    textTheme: base.textTheme.apply(
      fontFamily: SgText.family,
      fontFamilyFallback: SgText.fallback,
      bodyColor: p.ink,
      displayColor: p.ink,
    ),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: SgText.family,
      fontFamilyFallback: SgText.fallback,
    ),
  );
}
