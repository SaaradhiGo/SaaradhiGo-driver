import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Reusable glassmorphic container matching the SaaradhiGo design system.
/// Features a dark charcoal background with high blur backdrop filter,
/// rounded corners, and a subtle white border.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Border? border;
  final Color? backgroundColor;
  final double blur;
  final VoidCallback? onTap;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.border,
    this.backgroundColor,
    this.blur = 20.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color:
            backgroundColor ?? const Color(0xFF151515).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border:
            border ?? Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );

    content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
