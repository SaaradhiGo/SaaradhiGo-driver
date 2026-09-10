import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable Route Indicator widget showing pickup dot, gradient line, dropoff dot.
class RouteIndicator extends StatelessWidget {
  final double height;

  const RouteIndicator({super.key, this.height = 60.0});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pickup Dot
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: const Color(0xFF151515), width: 2),
          ),
        ),
        // Connecting Line
        Container(
          width: 2,
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.outlineVariant],
            ),
          ),
        ),
        // Dropoff Square
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: AppColors.surfaceVariant,
            border: Border.all(color: AppColors.outlineVariant, width: 2),
          ),
        ),
      ],
    );
  }
}
