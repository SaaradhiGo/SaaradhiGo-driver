import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Brand Colors
  static const Color primary = Color(0xFFF2CA50);
  static const Color primaryContainer = Color(0xFFD4AF37); // Primary Gold
  static const Color secondary = Color(0xFFECC156);

  // Gradients
  static const Color gradientStart = Color(0xFFF4C95D);
  static const Color gradientEnd = Color(0xFFB8860B);

  // Backgrounds & Surfaces (Midnight Obsidian & Charcoal)
  static const Color background = Color(0xFF0B0B0B);
  static const Color surface = Color(0xFF151515);
  static const Color surfaceContainer = Color(0xFF231F17);
  static const Color surfaceContainerHigh = Color(0xFF2D2A21);

  // Text Colors
  static const Color onBackground = Color(0xFFEAE1D4);
  static const Color onSurfaceVariant = Color(0xFFD0C5AF);
  static const Color whiteText = Color(0xFFFFFFFF);
  static const Color secondaryGray = Color(0xFFA1A1A1);
  static const Color darkText = Color(
    0xFF3C2F00,
  ); // For text on primary buttons

  // Borders & Outlines
  static const Color outline = Color(0xFF99907C);
  static const Color outlineVariant = Color(0xFF4D4635);

  // Semantics
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF81C784);
  static const Color successContainer = Color(0xFF1B381E);
  static const Color pendingContainer = Color(0xFF3E2E00);

  // Effects
  static const Color glassOverlay = Color(
    0xDA151515,
  ); // Charcoal at 85% opacity
  static const Color shadowGlow = Color(
    0x4DD4AF37,
  ); // Primary Gold at 30% opacity
}
