import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../requirements/requirements_api.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/appearance_controller.dart';
import '../../../../core/theme/locale_controller.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

/// Profile rows for Appearance (Automatic / Dark / Light) and Language
/// (English / Telugu / Hindi). Each opens a sheet of choices; both persist.
class DisplaySettingsRows extends ConsumerWidget {
  const DisplaySettingsRows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = _l10n(context);
    final mode = ref.watch(appearanceControllerProvider).mode;
    final locale = ref.watch(localeControllerProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(
          key: const Key('profile_appearance_tile'),
          icon: Icons.brightness_6_rounded,
          title: l10n.appearanceTitle,
          value: _modeLabel(l10n, mode),
          onTap: () => _pickAppearance(context, ref),
        ),
        Divider(height: 1, color: AppColors.outlineVariant),
        _row(
          key: const Key('profile_language_tile'),
          icon: Icons.translate_rounded,
          title: l10n.languageTitle,
          value: _languageLabel(l10n, locale.languageCode),
          onTap: () => _pickLanguage(context, ref),
        ),
      ],
    );
  }

  /// English when a host (a test, say) has no localizations delegate.
  static AppLocalizations _l10n(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));

  static String _modeLabel(AppLocalizations l10n, AppearanceMode m) =>
      switch (m) {
        AppearanceMode.automatic => l10n.appearanceAutomatic,
        AppearanceMode.dark => l10n.appearanceDark,
        AppearanceMode.light => l10n.appearanceLight,
      };

  static String _languageLabel(AppLocalizations l10n, String code) =>
      switch (code) {
        'te' => l10n.languageTelugu,
        'hi' => l10n.languageHindi,
        _ => l10n.languageEnglish,
      };

  Widget _row({
    required Key key,
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) => Material(
    color: Colors.transparent,
    child: ListTile(
      key: key,
      minTileHeight: AppSpacing.touchTarget,
      leading: Icon(icon, color: AppColors.primaryText),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(color: AppColors.onBackground),
      ),
      subtitle: Text(
        value,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
          fontSize: SgText.sizeSmall,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.onSurfaceVariant,
      ),
      onTap: onTap,
    ),
  );

  Future<void> _pickAppearance(BuildContext context, WidgetRef ref) async {
    final l10n = _l10n(context);
    final current = ref.read(appearanceControllerProvider).mode;
    final picked = await _choose<AppearanceMode>(
      context,
      title: l10n.appearanceTitle,
      current: current,
      options: [
        (AppearanceMode.light, l10n.appearanceLight, null),
        (AppearanceMode.dark, l10n.appearanceDark, l10n.appearanceDarkHint),
        (
          AppearanceMode.automatic,
          l10n.appearanceAutomatic,
          l10n.appearanceAutomaticHint,
        ),
      ],
    );
    if (picked != null) {
      await ref.read(appearanceControllerProvider.notifier).setMode(picked);
    }
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = _l10n(context);
    final current = ref.read(localeControllerProvider).languageCode;
    final offered = ref.read(requirementsProvider).value?.languages;
    final picked = await _choose<String>(
      context,
      title: l10n.languageTitle,
      current: current,
      // Only the market's languages (10 Nov), from the driver's requirements; the app has en/te/hi.
      options: [
        for (final o in [
          ('en', l10n.languageEnglish, null),
          ('te', l10n.languageTelugu, null),
          ('hi', l10n.languageHindi, null),
        ])
          if (offered == null || offered.contains(o.$1)) o,
      ],
    );
    if (picked != null) {
      await ref
          .read(localeControllerProvider.notifier)
          .setLocale(Locale(picked));
    }
  }

  static Future<T?> _choose<T>(
    BuildContext context, {
    required String title,
    required T current,
    required List<(T, String, String?)> options,
  }) => showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                title,
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
            ),
            for (final (value, label, hint) in options)
              ListTile(
                key: Key('choice_$value'),
                minTileHeight: AppSpacing.touchTarget,
                title: Text(
                  label,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
                subtitle: hint == null
                    ? null
                    : Text(
                        hint,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                trailing: value == current
                    ? Icon(Icons.check_rounded, color: AppColors.primaryText)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ],
        ),
      ),
    ),
  );
}
