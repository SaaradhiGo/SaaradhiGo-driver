import 'package:flutter/material.dart';

import '../../ui/sg_tokens.dart';

/// The older screens' token names, answering from the active design-system
/// palette (lib/ui/sg_tokens.dart). No colour literals here: every name is a
/// getter so the app can switch between the dark and light palettes.
///
/// [primary] is the gold FILL (buttons, markers, tints). Gold used as text, an
/// icon, a border or a progress stroke is [primaryText], which is darker in the
/// light theme so it stays readable on light surfaces.
class AppColors {
  AppColors._();

  static Color get primary => SgColors.gold500;
  static Color get primaryContainer => SgColors.gold500;
  static Color get secondary => SgColors.gold300;

  /// Gold as text, icon, border or stroke (4.5:1 on every surface).
  static Color get primaryText => SgColors.goldText;

  static Color get gradientStart => SgColors.gold500;
  static Color get gradientEnd => SgColors.gold500;

  static Color get background => SgColors.bg000;
  static Color get surface => SgColors.bg100;
  static Color get surfaceContainer => SgColors.bg200;
  static Color get surfaceContainerHigh => SgColors.bg300;

  static Color get onBackground => SgColors.ink;
  static Color get onSurfaceVariant => SgColors.inkMuted;
  static Color get whiteText => SgColors.ink;
  static Color get secondaryGray => SgColors.inkSubtle;

  /// Text and icons on a gold fill.
  static Color get darkText => SgColors.onGold;

  static Color get outline => SgColors.lineStrong;
  static Color get outlineVariant => SgColors.line;

  static Color get error => SgColors.danger;
  static Color get onError => SgColors.onDanger;
  static Color get errorContainer => SgColors.tint(SgColors.danger);
  static Color get success => SgColors.success;
  static Color get successContainer => SgColors.tint(SgColors.success);
  static Color get pendingContainer => SgColors.goldSoft;

  static Color get glassOverlay => SgColors.bg100;
  static Color get shadowGlow => Colors.transparent;
}
