/// Type styles (Tier 1): Anek for the interface, picked by the active locale
/// (AnekLatin / AnekTelugu / AnekDevanagari, the others as fallbacks), and
/// Cinzel 600 for the "Saaradhi Go" lettering beside the badge only.
///
/// Every style is a getter: colours come from the active palette and the
/// family from the active locale, both of which can change at runtime.
library;

import 'package:flutter/material.dart';

import 'sg_tokens.dart';

/// Size classes from the window's shortest side (owner brief, Tier 1).
enum SgSizeClass {
  compact(0.92),
  regular(1.0),
  tablet(1.12);

  const SgSizeClass(this.factor);

  final double factor;

  static SgSizeClass of(double shortestSide) => shortestSide < 360
      ? compact
      : shortestSide >= 600
      ? tablet
      : regular;
}

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

  /// The active language code.
  static String get languageCode => _languageCode;

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

  /// The size class, from the shortest side of the window: compact under
  /// 360, regular to 599, tablet from 600. Set by the app root.
  static SgSizeClass _sizeClass = SgSizeClass.regular;

  static SgSizeClass get sizeClass => _sizeClass;

  /// Sets the size class from the window's shortest side. True when it changed.
  static bool useShortestSide(double shortestSide) {
    final next = SgSizeClass.of(shortestSide);
    if (next == _sizeClass) return false;
    _sizeClass = next;
    return true;
  }

  /// [base] in this size class: every size in the app goes through here.
  static double size(double base) => base * _sizeClass.factor;

  static TextStyle _anek(
    double size,
    double line,
    double weight, {
    Color? color,
    bool figures = false,
  }) {
    final s = SgText.size(size);
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: s,
      height: line / size,
      fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      fontVariations: [
        FontVariation('wght', weight),
        FontVariation('wdth', 100),
      ],
      letterSpacing: 0,
      color: color ?? SgColors.ink,
      fontFeatures: figures ? const [FontFeature.tabularFigures()] : null,
    );
  }

  // The Tier 1 scale (owner brief, 6 Nov): sizes in logical pixels times the
  // size-class factor, weights 500, 600 and 700 only, no tracking.

  /// 24/30, 700. One per screen.
  static TextStyle get screenTitle => _anek(24, 30, 700);

  /// 18/24, 600.
  static TextStyle get sectionTitle => _anek(18, 24, 600);

  /// 16/24, 500.
  static TextStyle get body => _anek(16, 24, 500);

  /// 14/20, 500, ink-muted.
  static TextStyle get caption => _anek(14, 20, 500, color: SgColors.inkMuted);

  /// 13/18, 600, ink-subtle. Sentence case; never upper-cased.
  static TextStyle get label => _anek(13, 18, 600, color: SgColors.inkSubtle);

  /// 17/22, 600, on-gold.
  static TextStyle get button =>
      _anek(17, 22, 600, color: SgColors.onGold, figures: true);

  /// A figure in a tile or a row: section-title size at 700, tabular.
  static TextStyle get figure => _anek(18, 24, 700, figures: true);

  /// A large figure (the PIN digits, the trip-complete facts): 24/30, 700.
  static TextStyle get figureLg => _anek(24, 30, 700, figures: true);

  /// The big fare: 44 (40 on compact), 700.
  static TextStyle get bigFare => _sizeClass == SgSizeClass.compact
      ? _anek(40 / 0.92, 48 / 0.92, 700, figures: true)
      : _anek(44, 52, 700, figures: true);

  /// The driver's earning on the offer: 64 (56 on compact), 700.
  static TextStyle get driverEarning => _sizeClass == SgSizeClass.compact
      ? _anek(56 / 0.92, 60 / 0.92, 700, figures: true)
      : _anek(64, 68, 700, figures: true);

  // Older names, kept so every call site lands on the scale.
  static TextStyle get display => screenTitle;
  static TextStyle get displayLg => screenTitle;
  static TextStyle get heading => screenTitle;
  static TextStyle get title => sectionTitle;
  static TextStyle get bodyLg => body;
  static TextStyle get fareXl => bigFare;
  static TextStyle get fare => figure;

  /// "Saaradhi Go" beside the badge in headers: Cinzel 600, gold-text.
  static TextStyle brandLettering({double size = 18}) => TextStyle(
    fontFamily: brand,
    fontSize: size,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: SgColors.logo,
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
