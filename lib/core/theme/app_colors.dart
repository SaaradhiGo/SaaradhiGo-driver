import 'package:flutter/material.dart';

/// The older screens' tokens, mapped onto the design system (lib/ui/sg_tokens)
/// in group F so every screen reads pure black, ink and a single gold.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFFD700);
  static const Color primaryContainer = Color(0xFFFFD700);
  static const Color secondary = Color(0xFFFFE34D);

  // Gold is flat now; the gradient ends are the same colour.
  static const Color gradientStart = Color(0xFFFFD700);
  static const Color gradientEnd = Color(0xFFFFD700);

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceContainer = Color(0xFF18181B);
  static const Color surfaceContainerHigh = Color(0xFF27272A);

  static const Color onBackground = Color(0xFFF1F5F9);
  static const Color onSurfaceVariant = Color(0xFF94A3B8);
  static const Color whiteText = Color(0xFFF1F5F9);
  static const Color secondaryGray = Color(0xFF8090A6);
  static const Color darkText = Color(0xFF000000); // Text on gold.

  static const Color outline = Color(0xFF71717A);
  static const Color outlineVariant = Color(0xFF27272A);

  static const Color error = Color(0xFFFF8A6B);
  static const Color errorContainer = Color(0xFF3A1A12);
  static const Color success = Color(0xFF46C98B);
  static const Color successContainer = Color(0xFF12291E);
  static const Color pendingContainer = Color(0xFF2A2405);

  static const Color glassOverlay = Color(0xFF141414);
  static const Color shadowGlow = Color(0x00000000);
}
