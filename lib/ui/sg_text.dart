/// Type styles: Inter 400 and 600 for the interface (Noto Sans Telugu and
/// Devanagari as fallbacks) and Cinzel 600 for the "Saaradhi Go" lettering
/// beside the badge only.
///
/// Five sizes only (display 40/48, heading 28/36, title 20/28, body 16/24,
/// small 14/20; the compact class takes display 32/40 and heading 22/28) and
/// two weights (400 body, 600 headings, buttons, labels, nav). Screens use the
/// styles and the size tokens here, never a raw font size or weight
/// (test/ui/type_tokens_test.dart enforces it).
///
/// Every style is a getter: colours come from the active palette and the
/// size from the active size class, both of which can change at runtime.
library;

import 'package:flutter/material.dart';

import 'sg_tokens.dart';

/// Size classes from the window's shortest side. Only the tablet class
/// enlarges text (x1.12); the compact class changes display and heading only.
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

  static const latin = 'Inter';
  static const telugu = 'NotoSansTelugu';
  static const devanagari = 'NotoSansDevanagari';

  /// Brand lettering only. Never headings or body.
  static const brand = 'Cinzel';

  static String _languageCode = 'en';

  /// Set by the locale controller when the app language changes.
  static void useLanguage(String languageCode) => _languageCode = languageCode;

  /// Inter for every language.
  static String get family => latin;

  /// The active language code.
  static String get languageCode => _languageCode;

  static String familyFor(String languageCode) => latin;

  /// Telugu and Devanagari, so mixed-script text (a Telugu street name in an
  /// English UI) still renders. The active language's script comes first.
  static List<String> get fallback => fallbackFor(_languageCode);

  static List<String> fallbackFor(String languageCode) => languageCode == 'hi'
      ? const [devanagari, telugu]
      : const [telugu, devanagari];

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

  static bool get _compact => _sizeClass == SgSizeClass.compact;

  static double _sz(double regular, [double? compactSize]) =>
      _compact ? (compactSize ?? regular) : regular * _sizeClass.factor;

  /// The five sizes, in logical pixels for the active size class.
  static double get sizeDisplay => _sz(40, 32);
  static double get sizeHeading => _sz(28, 22);
  static double get sizeTitle => _sz(20);
  static double get sizeBody => _sz(16);
  static double get sizeSmall => _sz(14);

  static TextStyle _style(
    double size,
    double line,
    FontWeight weight, {
    double? compactSize,
    double? compactLine,
    Color? color,
    bool figures = false,
    double? letterSpacing,
  }) {
    final s = _sz(size, compactSize);
    final l = _sz(line, compactLine);
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: s,
      height: l / s,
      fontWeight: weight,
      letterSpacing: letterSpacing ?? 0,
      color: color ?? SgColors.ink,
      fontFeatures: figures ? const [FontFeature.tabularFigures()] : null,
    );
  }

  /// 40/48 (compact 32/40), 600, tabular: the big fare, the driver's earning.
  static TextStyle get display => _style(
    40,
    48,
    FontWeight.w600,
    compactSize: 32,
    compactLine: 40,
    figures: true,
  );

  /// 28/36 (compact 22/28), 600. One per screen.
  static TextStyle get heading =>
      _style(28, 36, FontWeight.w600, compactSize: 22, compactLine: 28);

  /// 20/28, 600.
  static TextStyle get title => _style(20, 28, FontWeight.w600);

  /// 16/24, 400.
  static TextStyle get body => _style(16, 24, FontWeight.w400);

  /// 14/20, 400, ink-muted.
  static TextStyle get small =>
      _style(14, 20, FontWeight.w400, color: SgColors.inkMuted);

  /// 14/20, 600, ink-subtle. Sentence case labels.
  static TextStyle get label =>
      _style(14, 20, FontWeight.w600, color: SgColors.inkSubtle);

  /// An UPPERCASE small label: label with 0.04em (0.56 at 14px) tracking.
  /// The only letter-spaced style; use it only on text that is upper-cased.
  static TextStyle get eyebrow =>
      label.copyWith(letterSpacing: 0.04 * sizeSmall);

  /// 16/24, 600, on-gold.
  static TextStyle get button =>
      _style(16, 24, FontWeight.w600, color: SgColors.onGold, figures: true);

  /// A figure in a tile or a row: title size at 600, tabular.
  static TextStyle get figure => _style(20, 28, FontWeight.w600, figures: true);

  /// A large figure (the PIN digits, the trip-complete facts): heading size.
  static TextStyle get figureLg => _style(
    28,
    36,
    FontWeight.w600,
    compactSize: 22,
    compactLine: 28,
    figures: true,
  );

  /// The big fare: display.
  static TextStyle get bigFare => display;

  /// The driver's earning on the offer: display.
  static TextStyle get driverEarning => display;

  // Older names, kept so every call site lands on the scale.
  static TextStyle get screenTitle => heading;
  static TextStyle get sectionTitle => title;
  static TextStyle get caption => small;
  static TextStyle get displayLg => heading;
  static TextStyle get bodyLg => body;
  static TextStyle get fareXl => display;
  static TextStyle get fare => figure;

  /// "Saaradhi Go" beside the badge in headers: Cinzel 600, gold-text.
  static TextStyle brandLettering({double size = 18}) => TextStyle(
    fontFamily: brand,
    fontSize: size,
    height: 1.1,
    fontWeight: FontWeight.w600,
    color: SgColors.logo,
  );

  /// Every Material text slot on one of the five sizes: display slots take
  /// display, headline slots heading, titleLarge title, the body slots body
  /// and the small slots small. Weights are 400 or 600 only.
  static TextTheme get textTheme {
    const strong = FontWeight.w600;
    final smallBody = body.copyWith(fontSize: sizeSmall, height: 20 / 14);
    return TextTheme(
      displayLarge: display,
      displayMedium: display,
      displaySmall: display,
      headlineLarge: heading,
      headlineMedium: heading,
      headlineSmall: heading,
      titleLarge: title,
      titleMedium: body.copyWith(fontWeight: strong),
      titleSmall: smallBody.copyWith(fontWeight: strong),
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: smallBody,
      labelLarge: body.copyWith(fontWeight: strong),
      labelMedium: smallBody.copyWith(fontWeight: strong),
      labelSmall: smallBody.copyWith(fontWeight: strong),
    );
  }
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
    textTheme: SgText.textTheme.apply(bodyColor: p.ink, displayColor: p.ink),
    primaryTextTheme: SgText.textTheme,
  );
}
