import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';

/// Blocking overlay for unusable location, per docs/10_LOCATION.md §4 and
/// docs/14_ERROR_HANDLING.md:16-17.
///
/// No Stitch design exists for these screens, so this is composed from
/// `docs/11_DESIGN_SYSTEM.md` tokens and the glass-panel idiom used elsewhere on
/// the dashboard. Rendered as an in-tree overlay rather than a `showDialog`
/// route so it cannot be dismissed by a barrier tap or a back gesture.
class LocationBlockedOverlay extends StatelessWidget {
  const LocationBlockedOverlay._({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onRetry,
  });

  /// Device location services are switched off.
  factory LocationBlockedOverlay.serviceDisabled({
    required VoidCallback onOpenSettings,
    required VoidCallback onRetry,
  }) {
    return LocationBlockedOverlay._(
      icon: Icons.location_off_outlined,
      title: 'Turn on Location',
      body:
          'Device location services are off. SaaradhiGo needs your live '
          'position to match you with nearby riders and to navigate trips.\n\n'
          'You cannot go online until location is enabled.',
      primaryLabel: 'Open Location Settings',
      onPrimary: onOpenSettings,
      onRetry: onRetry,
    );
  }

  /// Permission refused. [permanent] means the OS will no longer prompt.
  factory LocationBlockedOverlay.permissionDenied({
    required bool permanent,
    required VoidCallback onOpenSettings,
    required VoidCallback onRetry,
  }) {
    return LocationBlockedOverlay._(
      icon: Icons.my_location_outlined,
      title: 'Location Permission Needed',
      body: permanent
          ? 'Location access is blocked for SaaradhiGo. Ride requests are '
                'dispatched by proximity, so we cannot send you trips without '
                'it.\n\nEnable "Location" in app settings, then return here.'
          : 'SaaradhiGo uses your location to dispatch nearby ride requests '
                'and to share your progress with the rider during a trip.\n\n'
                'Grant location access to go online.',
      primaryLabel: permanent ? 'Open App Settings' : 'Grant Permission',
      onPrimary: onOpenSettings,
      onRetry: onRetry,
    );
  }

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.background.withValues(alpha: 0.88),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.margin),
              child: GlassPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(icon, size: 48, color: AppColors.primaryContainer),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(text: primaryLabel, onPressed: onPrimary),
                    const SizedBox(height: AppSpacing.sm),
                    GhostButton(
                      text: 'I\'ve done this — Retry',
                      onPressed: onRetry,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
