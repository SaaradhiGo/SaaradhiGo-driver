import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'app_server_image.dart';

/// Reusable avatar widget displaying driver photo with initials fallback and
/// optional verified checkmark badge.
class DriverAvatar extends StatelessWidget {
  const DriverAvatar({
    super.key,
    this.url,
    this.fallbackName,
    this.size = 40.0,
    this.isVerified = false,
    this.onTap,
    this.border,
  });

  final String? url;
  final String? fallbackName;
  final double size;
  final bool isVerified;
  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final name = (fallbackName == null || fallbackName!.trim().isEmpty)
        ? 'Driver'
        : fallbackName!.trim();
    final initial = name.characters.first.toUpperCase();
    final badgeSize = (size * 0.32).clamp(16.0, 28.0);

    Widget avatarContent;
    if (url != null && url!.trim().isNotEmpty) {
      avatarContent = AppServerImage(
        url: url!,
        placeholder: (context, url) => _buildInitials(initial),
        errorWidget: (context, url, error) => _buildInitials(initial),
      );
    } else {
      avatarContent = _buildInitials(initial);
    }

    Widget avatarWidget = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerHigh,
        border:
            border ??
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: avatarContent,
    );

    if (isVerified) {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.verified_rounded,
                size: badgeSize * 0.75,
                color: AppColors.primaryContainer,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildInitials(String initial) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          initial,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.primaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}
