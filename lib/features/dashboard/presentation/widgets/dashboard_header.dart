import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/driver_profile_model.dart';
import '../../../../shared/widgets/driver_avatar.dart';
import '../../../../shared/widgets/glass_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Glass header from `driver_home_dashboard/code.html:144-161`: avatar, name,
/// rating, vehicle details, notification bell.
///
/// Covers the profile Loading / Error / Success states inline; the dashboard
/// never blanks because the profile call failed.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key, required this.profileState});

  final ProfileState profileState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return GlassPanel(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppSpacing.radiusLg),
      ),
      padding: EdgeInsets.only(
        top: topInset + AppSpacing.gutter,
        bottom: AppSpacing.md,
        left: AppSpacing.margin,
        right: AppSpacing.margin,
      ),
      child: Row(
        children: [
          Expanded(child: _buildIdentity(context)),
          _NotificationBell(
            unreadCount: unreadCount,
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(BuildContext context) {
    return switch (profileState) {
      ProfileStateLoaded(:final profile) => _Identity(profile: profile),
      ProfileStateError(:final message) => _HeaderMessage(
        icon: Icons.error_outline,
        text: message,
        color: AppColors.error,
      ),
      _ => const _HeaderMessage(
        icon: null,
        text: 'Loading profile…',
        color: AppColors.onSurfaceVariant,
      ),
    };
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile});

  final DriverProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.user?.fullName?.trim();
    final displayName = (name == null || name.isEmpty) ? 'Driver' : name;
    final avatarUrl = profile.user?.avatar;
    final rating = profile.ratings;

    // Format active vehicle details if available
    final vehicleDetails = profile.activeVehicleDetails;
    String? vehicleSubtitle;
    if (vehicleDetails != null) {
      final brand = vehicleDetails['brand']?.toString() ?? '';
      final model = vehicleDetails['model']?.toString() ?? '';
      final number = vehicleDetails['vehicle_number']?.toString() ?? '';
      final nameStr = '$brand $model'.trim();

      if (nameStr.isNotEmpty && number.isNotEmpty) {
        vehicleSubtitle = '$nameStr • $number';
      } else if (number.isNotEmpty) {
        vehicleSubtitle = number;
      } else if (nameStr.isNotEmpty) {
        vehicleSubtitle = nameStr;
      }
    }

    return InkWell(
      onTap: () => context.push('/profile'),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        child: Row(
          children: [
            DriverAvatar(
              url: avatarUrl,
              fallbackName: displayName,
              size: 44,
              isVerified: profile.approved,
              onTap: () => context.push('/profile'),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (rating != null) ...[
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTypography.dataMono.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.star,
                          size: 13,
                          color: AppColors.primaryContainer,
                        ),
                      ],
                      if (rating != null && vehicleSubtitle != null)
                        Text(
                          '  •  ',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      if (vehicleSubtitle != null)
                        Expanded(
                          child: Text(
                            vehicleSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderMessage extends StatelessWidget {
  const _HeaderMessage({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData? icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Icon(icon, size: 18, color: color),
          )
        else
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMd.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unreadCount, required this.onTap});

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceContainer,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              size: 20,
              color: AppColors.onBackground,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.background,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
