import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import '../../ui/sg_text.dart';
import '../../ui/sg_tokens.dart';

class AppTheme {
  AppTheme._();

  /// The dark theme, whatever palette is active.
  static ThemeData get darkTheme => of(SgPalette.dark);

  /// The light theme, whatever palette is active.
  static ThemeData get lightTheme => of(SgPalette.light);

  /// The theme for [palette]. Every token below is read while [palette] is
  /// the active one, then the previous palette is restored.
  static ThemeData of(SgPalette palette) {
    final previous = SgColors.palette;
    SgColors.use(palette);
    try {
      return _build();
    } finally {
      SgColors.use(previous);
    }
  }

  static ThemeData _build() {
    final scheme = SgColors.isDark ? ColorScheme.dark : ColorScheme.light;
    return ThemeData(
      useMaterial3: true,
      fontFamily: SgText.family,
      fontFamilyFallback: SgText.fallback,
      brightness: SgColors.palette.brightness,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme(
        primary: AppColors.primary,
        onPrimary: AppColors.darkText,
        secondary: AppColors.secondary,
        onSecondary: AppColors.darkText,
        surface: AppColors.surface,
        onSurface: AppColors.onBackground,
        error: AppColors.error,
        onError: AppColors.onError,
      ),
      textTheme: SgText.textTheme.apply(
        bodyColor: AppColors.onBackground,
        displayColor: AppColors.whiteText,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: AppColors.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.darkText,
          // Height floor only. Do NOT use `Size.fromHeight` here: it means
          // `Size(double.infinity, h)`, i.e. an infinite *minimum width*. A
          // themed button placed in a `Row` (unbounded main axis) then throws
          // "BoxConstraints forces an infinite width" during layout, which
          // aborts the parent RenderFlex mid-layout and leaves siblings
          // unsized — surfacing later as "Cannot hit test a render box with no
          // size" / "RenderBox was not laid out". Buttons that want to stretch
          // opt in themselves (see PrimaryButton/SecondaryButton/GhostButton).
          minimumSize: const Size(0, AppSpacing.touchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.whiteText,
          // Height floor only — see the note on `elevatedButtonTheme` above.
          minimumSize: const Size(0, AppSpacing.touchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          side: BorderSide(color: AppColors.outline),
          textStyle: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSm.copyWith(
          color: AppColors.onBackground,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainer,
        contentTextStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.onBackground,
        ),
        actionTextColor: AppColors.primaryText,
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: AppColors.outlineVariant),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.primaryText),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        floatingLabelStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}
