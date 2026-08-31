import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.darkText,
        secondary: AppColors.secondary,
        onSecondary: AppColors.darkText,
        surface: AppColors.surface,
        onSurface: AppColors.onBackground,
        error: AppColors.error,
        onError: AppColors.background,
      ),
      textTheme:
          TextTheme(
            displayLarge: AppTypography.displayLg,
            headlineLarge: AppTypography.headlineLgMobile,
            headlineMedium: AppTypography.headlineMd,
            headlineSmall: AppTypography.headlineSm,
            bodyLarge: AppTypography.bodyLg,
            bodyMedium: AppTypography.bodyMd,
            labelSmall: AppTypography.labelCaps,
          ).apply(
            bodyColor: AppColors.onBackground,
            displayColor: AppColors.whiteText,
          ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(
            color: Color(0x1AFFFFFF), // 10% white inner border simulation
            width: 1,
          ),
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
          minimumSize: const Size(0, AppSpacing.primaryButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
          side: const BorderSide(
            color: Color(0x66FFFFFF),
            width: 1,
          ), // 40% white
          textStyle: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        floatingLabelStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
}
