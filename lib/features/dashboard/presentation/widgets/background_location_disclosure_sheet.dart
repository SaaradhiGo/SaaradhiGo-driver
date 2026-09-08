import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';

/// Luxury bottom sheet providing Google Play compliant background location disclosure
/// and escalation to `LocationPermission.always`.
class BackgroundLocationDisclosureSheet extends ConsumerWidget {
  const BackgroundLocationDisclosureSheet({
    super.key,
    this.onGranted,
    this.onDismiss,
  });

  final VoidCallback? onGranted;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDismiss,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackgroundLocationDisclosureSheet(
        onGranted: onGranted,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon with gold pulse
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Title
                      Text(
                        'Background Location Access',
                        style: AppTypography.headlineMd.copyWith(
                          color: AppColors.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Prominent disclosure text (Google Play compliance)
                      Text(
                        'SaaradhiGo Driver collects and streams your location data to enable incoming ride dispatches, route tracking, and accurate passenger ETAs even when the app is closed, minimized, or the screen is locked.',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Perks card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            _buildPerkRow(
                              Icons.notifications_active,
                              'Never miss a nearby dispatch while using external navigation maps',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildPerkRow(
                              Icons.battery_charging_full,
                              'Battery-optimized with 10m / 5s adaptive coordinate throttling',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildPerkRow(
                              Icons.shield,
                              'Location is only tracked while you are actively toggled Online',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Primary CTA: Grant Background Access
                      PrimaryButton(
                        text: 'Grant "Allow All The Time"',
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final notifier = ref.read(
                            locationNotifierProvider.notifier,
                          );
                          final result = await notifier
                              .requestBackgroundPermission();
                          if (!result.hasBackgroundAccess) {
                            // Open OS App Settings where "Allow all the time" can be selected
                            await notifier.openAppSettings();
                          }
                          onGranted?.call();
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Secondary CTA: Continue in Limited Mode
                      SecondaryButton(
                        text: 'Continue in Limited Mode',
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDismiss?.call();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerkRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onBackground,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
