import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/trip_providers.dart';

/// Driver-cancellation reasons accepted by the backend
/// (`POST /ride/trip/<id>/driver-cancel/` and the socket `cancel` action):
/// `no_show | vehicle_issue | safety | personal | other`.
const _cancelReasons = <(String, String)>[
  ('no_show', 'Rider is a no-show'),
  ('vehicle_issue', 'Vehicle issue'),
  ('safety', 'Safety concern'),
  ('personal', 'Personal emergency'),
  ('other', 'Other'),
];

/// Presents the cancellation reason picker and, on selection, cancels the trip
/// over the socket. The reason is required by the backend.
Future<void> showCancelTripSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.margin,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancel this ride?',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a reason. Frequent cancellations can affect your rating.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final (code, label) in _cancelReasons)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    label,
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.onBackground,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onTap: () {
                    ref
                        .read(tripSessionNotifierProvider.notifier)
                        .cancelTrip(reason: code);
                    Navigator.pop(sheetCtx);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
