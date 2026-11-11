/// Design-system tokens for the hybrid design (Tier 1): one dark and one light
/// palette, switched at runtime by the appearance controller
/// (lib/core/theme/appearance_controller.dart).
///
/// This is the ONLY file in lib/ allowed to spell a colour as a literal
/// (test/ui/no_raw_colours_test.dart enforces it). Everything else reads the
/// [SgColors] getters, which always answer from the active palette.
library;

import 'package:flutter/material.dart';

/// Every colour token, for one theme.
@immutable
class SgPalette {
  const SgPalette({
    required this.brightness,
    required this.bg000,
    required this.bg100,
    required this.bg200,
    required this.bg300,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.gold500,
    required this.gold300,
    required this.gold700,
    required this.onGold,
    required this.goldText,
    required this.goldLine,
    required this.goldSoft,
    required this.logo,
    required this.bgGlass,
    required this.scrim,
    required this.shadow,
    required this.pickup,
    required this.success,
    required this.danger,
    required this.onDanger,
    required this.classBike,
    required this.classAuto,
    required this.classCar,
    required this.classComfort,
    required this.classSuv,
  });

  final Brightness brightness;

  // Neutrals (warm).
  final Color bg000;
  final Color bg100;
  final Color bg200;
  final Color bg300;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;

  // Brand gold.
  final Color gold500;
  final Color gold300;
  final Color gold700;
  final Color onGold;
  final Color goldText;
  final Color goldLine;
  final Color goldSoft;

  /// The logo's colour: gold on dark, deep gold #7A6000 on light.
  final Color logo;

  // Surfaces over the map.
  final Color bgGlass;
  final Color scrim;

  /// Drop shadow for the few raised surfaces left (never a glow).
  final Color shadow;

  // Status.
  final Color pickup;
  final Color success;
  final Color danger;
  final Color onDanger;

  // Vehicle classes (icon colour; the tile is a 14% tint over bg-100).
  final Color classBike;
  final Color classAuto;
  final Color classCar;
  final Color classComfort;
  final Color classSuv;

  bool get isDark => brightness == Brightness.dark;

  static const dark = SgPalette(
    brightness: Brightness.dark,
    bg000: Color(0xFF000000),
    bg100: Color(0xFF0F0F0F),
    bg200: Color(0xFF181818),
    bg300: Color(0xFF242424),
    line: Color(0xFF262626),
    lineStrong: Color(0xFF6E6A63),
    ink: Color(0xFFF3EEE6),
    inkMuted: Color(0xFFB4ADA2),
    inkSubtle: Color(0xFF948E84),
    gold500: Color(0xFFFFD700),
    gold300: Color(0xFFFFE34D),
    gold700: Color(0xFFD4B200),
    onGold: Color(0xFF000000),
    goldText: Color(0xFFFFD700),
    goldLine: Color(0x38FFD700), // rgba(255,215,0,0.22)
    goldSoft: Color(0x1AFFD700), // rgba(255,215,0,0.10)
    logo: Color(0xFFFFD700),
    bgGlass: Color(0xCC0A0A0A),
    scrim: Color(0x99000000),
    shadow: Color(0x99000000),
    pickup: Color(0xFF46C98B),
    success: Color(0xFF46C98B),
    danger: Color(0xFFFF6B5E),
    onDanger: Color(0xFF000000),
    classBike: Color(0xFF8AB4FF),
    classAuto: Color(0xFF4FD1A5),
    classCar: Color(0xFFF2A65A),
    classComfort: Color(0xFFB9A3FF),
    classSuv: Color(0xFFAAB6C8),
  );

  static const light = SgPalette(
    brightness: Brightness.light,
    bg000: Color(0xFFFAF7F2),
    bg100: Color(0xFFFFFFFF),
    bg200: Color(0xFFF3EEE6),
    bg300: Color(0xFFE9E3D9),
    line: Color(0xFFE7E1D7),
    lineStrong: Color(0xFF8C8579),
    ink: Color(0xFF1B1A17),
    inkMuted: Color(0xFF57524A),
    inkSubtle: Color(0xFF6B655B),
    // Daylight (owner brief, 6 Nov): a marigold primary with ink on it, and
    // #8A5300 for gold as text and links.
    gold500: Color(0xFFF5A623),
    gold300: Color(0xFFF8BF5E),
    gold700: Color(0xFFD48A0E),
    onGold: Color(0xFF1B1A17),
    goldText: Color(0xFF8A5300),
    goldLine: Color(0x478A5300), // rgba(138,83,0,0.28)
    goldSoft: Color(0x24F5A623), // rgba(245,166,35,0.14)
    logo: Color(0xFF7A6000),
    bgGlass: Color(0xE6FFFFFF),
    scrim: Color(0x66000000),
    shadow: Color(0x1F000000),
    // Spec #0E7C66 is 4.44:1 as text on bg-200; #0D7762 (same as web) passes.
    pickup: Color(0xFF0D7762),
    success: Color(0xFF0B6B57),
    danger: Color(0xFFB3261E),
    onDanger: Color(0xFFFFFFFF),
    classBike: Color(0xFF1D4ED8),
    classAuto: Color(0xFF0B6B57),
    classCar: Color(0xFF8A5300),
    classComfort: Color(0xFF5B3FA8),
    classSuv: Color(0xFF334155),
  );
}

/// The active palette's tokens. Getters, not constants: the theme can change
/// while the app runs (automatic day/night), so nothing may capture a colour
/// in a `const` or a `static final`.
class SgColors {
  SgColors._();

  static SgPalette _active = SgPalette.dark;

  /// The palette every getter answers from.
  static SgPalette get palette => _active;

  /// Switch palettes. Called by the appearance controller only (and tests).
  static void use(SgPalette palette) => _active = palette;

  static bool get isDark => _active.isDark;

  static Color get bg000 => _active.bg000;
  static Color get bg100 => _active.bg100;
  static Color get bg200 => _active.bg200;
  static Color get bg300 => _active.bg300;
  static Color get line => _active.line;
  static Color get lineStrong => _active.lineStrong;
  static Color get ink => _active.ink;
  static Color get inkMuted => _active.inkMuted;
  static Color get inkSubtle => _active.inkSubtle;
  static Color get gold500 => _active.gold500;
  static Color get gold300 => _active.gold300;
  static Color get gold700 => _active.gold700;
  static Color get onGold => _active.onGold;
  static Color get goldText => _active.goldText;
  static Color get goldSoft => _active.goldSoft;
  static Color get goldLine => _active.goldLine;
  static Color get logo => _active.logo;
  static Color get bgGlass => _active.bgGlass;
  static Color get scrim => _active.scrim;
  static Color get pickup => _active.pickup;
  static Color get success => _active.success;
  static Color get danger => _active.danger;
  static Color get onDanger => _active.onDanger;
  static Color get classBike => _active.classBike;
  static Color get classAuto => _active.classAuto;
  static Color get classCar => _active.classCar;
  static Color get classComfort => _active.classComfort;
  static Color get classSuv => _active.classSuv;

  static Color get shadow => _active.shadow;

  /// Print-only brand gold; never UI. Kept here so it has a name.
  static const logoClassic = Color(0xFFD6A83E);

  /// Premium / black class: champagne icon on a pure black tile, both themes.
  static const champagne = Color(0xFFFFF4BF);
  static const premiumTile = Color(0xFF000000);

  /// Fixed colours that do not follow the theme.
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // Basemap tokens (dark basemap in both themes for now; see map_style.dart).
  static const mapGround = Color(0xFF0A0A0A);
  static const mapStreet = Color(0xFF18181B);
  static const mapArterial = Color(0xFF27272A);
  static const mapHighway = Color(0xFF3A3205);
  static const mapWater = Color(0xFF0A1418);
  static const mapPark = Color(0xFF0D140E);

  /// [c] at [alpha] composited over [base] (default bg-100): an opaque tint.
  static Color tint(Color c, {double alpha = 0.14, Color? base}) =>
      Color.alphaBlend(c.withValues(alpha: alpha), base ?? bg100);
}

/// Vehicle classes the design colours. Backend vehicle type codes map onto
/// these with [SgVehicleClass.fromCode]; show only classes pricing returns.
enum SgVehicleClass {
  bike,
  auto,
  car,
  comfort,
  suv,
  premium;

  /// Maps a backend vehicle type code to its class. One mapping shared by the
  /// rider app, the driver app and the website: bike -> bike; auto -> auto;
  /// hatchback, mini -> car; sedan -> comfort; suv -> suv; premium, black,
  /// luxury -> premium. Unknown codes -> null (neutral: ink on a bg-300 tile).
  static SgVehicleClass? fromCode(String? code) =>
      switch ((code ?? '').trim().toLowerCase()) {
        'bike' => SgVehicleClass.bike,
        'auto' => SgVehicleClass.auto,
        'hatchback' || 'mini' => SgVehicleClass.car,
        'sedan' => SgVehicleClass.comfort,
        'suv' => SgVehicleClass.suv,
        'premium' || 'black' || 'luxury' => SgVehicleClass.premium,
        _ => null,
      };

  /// Icon colour for a backend code; neutral ink when the code is unknown.
  static Color iconColorFor(String? code) =>
      fromCode(code)?.color ?? SgColors.ink;

  /// Tile colour for a backend code; neutral bg-300 when the code is unknown.
  static Color tileColorFor(String? code) =>
      fromCode(code)?.tile ?? SgColors.bg300;

  /// Icon colour in the active palette.
  Color get color => colorIn(SgColors.palette);

  /// Tile colour behind the icon in the active palette.
  Color get tile => tileIn(SgColors.palette);

  Color colorIn(SgPalette p) => switch (this) {
    SgVehicleClass.bike => p.classBike,
    SgVehicleClass.auto => p.classAuto,
    SgVehicleClass.car => p.classCar,
    SgVehicleClass.comfort => p.classComfort,
    SgVehicleClass.suv => p.classSuv,
    SgVehicleClass.premium => SgColors.champagne,
  };

  Color tileIn(SgPalette p) => this == SgVehicleClass.premium
      ? SgColors.premiumTile
      : Color.alphaBlend(colorIn(p).withValues(alpha: 0.14), p.bg100);
}

class SgRadius {
  SgRadius._();
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

class SgSpace {
  SgSpace._();
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
  static const s7 = 48.0;
}

/// Minimum touch target in the driver app (owner brief: 56).
const double kSgTouch = 56;

/// Minimum height of a primary driver action: Accept, Go online, Start,
/// Complete, the PIN confirm (owner brief: 64). Grows with the text size.
const double kSgPrimaryAction = 64;

/// Motion: press feedback and sheets, ease-out.
const Duration kSgPress = Duration(milliseconds: 140);
const Duration kSgSheet = Duration(milliseconds: 240);

/// The signed-in designs (2026-11-08): the dark chrome -- the top bar with the
/// DRIVER badge, the home sheet and the tab bar -- is the same in both themes.
class SgNoir {
  SgNoir._();
  static const bar = Color(0xFF0B0B0B);
  static const sheet = Color(0xFF1B1A17);
  static const tile = Color(0xFF262420);
  static const pill = Color(0xFF2E2C28);
  static const ink = Color(0xFFF3EEE6);
  static const inkMuted = Color(0xFFA8A29A);
  static const pillInk = Color(0xFFD8D2C6);
  static const gold = Color(0xFFF5C451);
  static const line = Color(0xFF3A3A3A);
  static const amber = Color(0xFFF5A623);
  static const onAmber = Color(0xFF1B1A17);
}

/// Status tints from the designs (ok, warn, err), per theme.
class SgStatus {
  SgStatus._();
  static Color get okBg =>
      SgColors.isDark ? const Color(0xFF12332A) : const Color(0xFFDDF1E6);
  static Color get okInk =>
      SgColors.isDark ? const Color(0xFF46C98B) : const Color(0xFF0B6B57);
  static Color get warnBg =>
      SgColors.isDark ? const Color(0xFF3A2C10) : const Color(0xFFFCEFD3);
  static Color get warnLine =>
      SgColors.isDark ? const Color(0xFF5A4518) : const Color(0xFFF0D9A8);
  static Color get warnInk =>
      SgColors.isDark ? const Color(0xFFF5C451) : const Color(0xFF7A4A00);
  static Color get rowFill =>
      SgColors.isDark ? const Color(0xFF242424) : const Color(0xFFF3EEE6);
  static Color get disabledBg =>
      SgColors.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE7E1D7);
  static Color get disabledInk =>
      SgColors.isDark ? const Color(0xFF8C8579) : const Color(0xFF8A857C);
}
