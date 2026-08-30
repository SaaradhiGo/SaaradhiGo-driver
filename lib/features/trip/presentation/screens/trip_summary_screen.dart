import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../providers/trip_providers.dart';

/// State `completed` — post-drop-off confirmation and earnings.
class TripSummaryScreen extends ConsumerWidget {
  const TripSummaryScreen({super.key, required this.trip});

  final TripModel trip;

  String get _fare {
    final raw = trip.finalFare ?? trip.estimatedFare ?? '0';
    return raw.startsWith('₹') ? raw : '₹$raw';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryContainer,
                  size: 56,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Trip Completed',
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You earned for this ride',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _fare,
                style: AppTypography.dataMono.copyWith(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 44,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassPanel(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric(
                      'DISTANCE',
                      trip.distanceKm != null
                          ? '${trip.distanceKm!.toStringAsFixed(1)} km'
                          : '—',
                    ),
                    _divider(),
                    _metric(
                      'DURATION',
                      trip.durationMin != null
                          ? '${trip.durationMin!.round()} min'
                          : '—',
                    ),
                    _divider(),
                    _metric(
                      'PAYMENT',
                      (trip.paymentMethod ?? 'Digital').toUpperCase(),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'BACK TO DASHBOARD',
                onPressed: () {
                  ref.read(tripSessionNotifierProvider.notifier).clear();
                  context.go('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    color: AppColors.outlineVariant.withValues(alpha: 0.2),
  );

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyLg.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
