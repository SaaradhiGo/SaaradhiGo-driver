import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Frosted charcoal surface used for floating overlays on top of the map.
///
/// Mirrors the `.glass-panel` idiom in the Stitch designs (see
/// `driver_home_dashboard/code.html`): a blurred backdrop filled with
/// [AppColors.glassOverlay] and hairlined with [AppColors.outlineVariant].
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius,
    this.borderColor,
    this.glowColor,
    this.blurSigma = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  /// Defaults to a subtle [AppColors.outlineVariant] hairline.
  final Color? borderColor;

  /// Optional outer glow — used for the "online" state of the status toggle.
  final Color? glowColor;

  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    // A flat panel on the design system; blur and glow are kept as
    // parameters for callers but no longer drawn.
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? AppColors.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
