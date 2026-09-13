import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/trip_history_state.dart';

class DateRangePickerSheet extends StatelessWidget {
  final DateFilterPreset activePreset;
  final DateTimeRange? activeCustomRange;
  final void Function(DateFilterPreset preset, DateTimeRange? customRange)
  onSelected;

  const DateRangePickerSheet({
    super.key,
    required this.activePreset,
    this.activeCustomRange,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required DateFilterPreset activePreset,
    DateTimeRange? activeCustomRange,
    required void Function(DateFilterPreset preset, DateTimeRange? customRange)
    onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DateRangePickerSheet(
        activePreset: activePreset,
        activeCustomRange: activeCustomRange,
        onSelected: onSelected,
      ),
    );
  }

  Future<void> _handleCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: todayEnd,
      initialDateRange:
          activeCustomRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: todayEnd,
          ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.darkText,
              surface: AppColors.surfaceContainer,
              onSurface: AppColors.onBackground,
              secondary: AppColors.primaryContainer,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surfaceContainer,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      onSelected(DateFilterPreset.custom, picked);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.margin,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Filter by Date',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Select a date preset or define a custom time window',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildPresetTile(context, DateFilterPreset.allTime),
            _buildPresetTile(context, DateFilterPreset.today),
            _buildPresetTile(context, DateFilterPreset.thisWeek),
            _buildPresetTile(context, DateFilterPreset.thisMonth),
            const Divider(
              color: AppColors.outlineVariant,
              height: AppSpacing.md,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                'Custom Date Range...',
                style: AppTypography.bodyMd.copyWith(
                  color: activePreset == DateFilterPreset.custom
                      ? AppColors.primary
                      : AppColors.onBackground,
                  fontWeight: activePreset == DateFilterPreset.custom
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              subtitle: activeCustomRange != null
                  ? Text(
                      '${activeCustomRange!.start.day}/${activeCustomRange!.start.month}/${activeCustomRange!.start.year} - '
                      '${activeCustomRange!.end.day}/${activeCustomRange!.end.month}/${activeCustomRange!.end.year}',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
              trailing: activePreset == DateFilterPreset.custom
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => _handleCustomDateRange(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetTile(BuildContext context, DateFilterPreset preset) {
    final isSelected = activePreset == preset;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        preset.label,
        style: AppTypography.bodyMd.copyWith(
          color: isSelected ? AppColors.primary : AppColors.onBackground,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        onSelected(preset, null);
        Navigator.pop(context);
      },
    );
  }
}
