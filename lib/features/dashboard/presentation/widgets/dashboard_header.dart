import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/driver_profile_model.dart';
import '../../../../shared/widgets/app_server_image.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Glass header from `driver_home_dashboard/code.html:144-161`: avatar, name,
/// rating, notification bell.
///
/// Covers the profile Loading / Error / Success states inline; the dashboard
/// never blanks because the profile call failed.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.profileState});

  final ProfileState profileState;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

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
          Expanded(child: _buildIdentity()),
          // Notifications are a later phase and there is no documented
          // /driver/notifications/ endpoint, so the bell renders disabled rather
          // than pretending to be actionable.
          const _NotificationBell(enabled: false),
        ],
      ),
    );
  }

  Widget _buildIdentity() {
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

    return Row(
      children: [
        _Avatar(url: avatarUrl, fallbackInitial: displayName),
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
              if (rating != null)
                Row(
                  children: [
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppTypography.dataMono.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.unit),
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: AppColors.primaryContainer,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.fallbackInitial});

  final String? url;
  final String fallbackInitial;

  @override
  Widget build(BuildContext context) {
    final initial = fallbackInitial.isEmpty
        ? '?'
        : fallbackInitial.characters.first.toUpperCase();

    return Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerHigh,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: (url == null || url!.isEmpty)
          ? Center(
              child: Text(
                initial,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : AppServerImage(url: url!),
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
  const _NotificationBell({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
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
        child: const Center(
          child: Icon(
            Icons.notifications_outlined,
            size: 20,
            color: AppColors.onBackground,
          ),
        ),
      ),
    );
  }
}
