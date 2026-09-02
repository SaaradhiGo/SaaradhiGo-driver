import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Persistent top banner shown while the device has no usable network
/// transport (docs/14_ERROR_HANDLING.md:11).
///
/// Rendered once, app-wide, on top of the tab shell and full-screen ride/
/// support routes so the driver always knows why live features (dispatch,
/// trip socket, chat) are unavailable and that retries are automatic once
/// connectivity returns.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 18,
                color: AppColors.whiteText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'No Internet Connection. Retrying…',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.whiteText,
                  ),
                ),
              ),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.whiteText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
