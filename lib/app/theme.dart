import 'package:flutter/material.dart';

/// Material 3 theme, light + dark.
///
/// Dark is not decoration here: drivers work nights, and a white screen at
/// 2am in a car is both blinding and a safety problem. Both schemes are built
/// from one seed so the two stay in step.
class AppTheme {
  const AppTheme._();

  /// VahanGo brand green. Chosen as the seed rather than hardcoding a palette
  /// so Material 3 derives contrast-correct containers for both brightnesses.
  static const Color brand = Color(0xFF00C853);
  static const Color danger = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);
  static const Color online = Color(0xFF00C853);
  static const Color offline = Color(0xFF757575);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF101314) : const Color(0xFFF6F7F9),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Big targets: this is used one-handed, often in motion, sometimes
          // with a phone mounted on a dashboard.
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

/// Spacing scale. Keeps padding consistent without a magic number per screen.
class Gap {
  const Gap._();
  static const Widget xs = SizedBox(height: 4, width: 4);
  static const Widget s = SizedBox(height: 8, width: 8);
  static const Widget m = SizedBox(height: 16, width: 16);
  static const Widget l = SizedBox(height: 24, width: 24);
  static const Widget xl = SizedBox(height: 32, width: 32);
}
