import 'dart:ui';

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
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);
    final glow = glowColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: glow == null
            ? const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : [BoxShadow(color: glow, blurRadius: 18, spreadRadius: 1)],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.glassOverlay,
              borderRadius: radius,
              border: Border.all(
                color:
                    borderColor ??
                    AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
