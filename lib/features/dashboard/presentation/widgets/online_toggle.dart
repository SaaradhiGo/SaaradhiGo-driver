import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../providers/availability_state.dart';

/// Floating status pill from `driver_home_dashboard/code.html:171-179`.
///
/// Copy follows the Stitch design ("You're Online" / "You're Offline") rather
/// than docs/02_UI_SPEC.md's "GO ONLINE" button, since the designs are the
/// visual source of truth.
class OnlineToggle extends StatelessWidget {
  const OnlineToggle({
    super.key,
    required this.state,
    required this.onPressed,
    this.enabled = true,
  });

  final AvailabilityState state;
  final VoidCallback onPressed;

  /// False renders the Disabled state — e.g. no network, or a guard is blocking.
  final bool enabled;

  bool get _isOnline => state.isOnline;

  String get _label => switch (state) {
    AvailabilityStateOnline() => "You're Online",
    AvailabilityStateGoingOnline() => 'Going online…',
    AvailabilityStateGoingOffline() => 'Going offline…',
    AvailabilityStateReconnecting() => 'Reconnecting…',
    _ => "You're Offline",
  };

  Color get _dotColor {
    if (!enabled) return AppColors.outlineVariant;
    return switch (state) {
      AvailabilityStateOnline() => AppColors.primaryContainer,
      AvailabilityStateReconnecting() => AppColors.primary,
      AvailabilityStateError() => AppColors.error,
      _ => AppColors.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final showSpinner = state.isTransitioning;

    return Semantics(
      button: true,
      enabled: enabled,
      label: _label,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.55,
        child: GestureDetector(
          onTap: enabled ? onPressed : null,
          child: GlassPanel(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            borderColor: _isOnline
                ? AppColors.primaryContainer.withValues(alpha: 0.4)
                : null,
            glowColor: _isOnline ? AppColors.shadowGlow : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSpinner)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dotColor,
                      boxShadow: _isOnline
                          ? const [
                              BoxShadow(
                                color: AppColors.shadowGlow,
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                const SizedBox(width: AppSpacing.gutter),
                Text(
                  _label,
                  style: AppTypography.headlineMd.copyWith(
                    color: _isOnline
                        ? AppColors.onBackground
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
