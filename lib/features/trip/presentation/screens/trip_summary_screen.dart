import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../earnings/presentation/widgets/cash_collection_dialog.dart';
import '../providers/trip_providers.dart';

/// State `completed` — post-drop-off confirmation and earnings. For a cash trip
/// the driver must confirm collection (`{"action":"confirm_cash"}`) before
/// returning to the dashboard; the socket is held open for that.
class TripSummaryScreen extends ConsumerStatefulWidget {
  const TripSummaryScreen({super.key, required this.trip});

  final TripModel trip;

  @override
  ConsumerState<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends ConsumerState<TripSummaryScreen> {
  bool _promptShown = false;

  TripModel get trip => widget.trip;

  /// Full client fare the rider pays in cash (driver collects the gross, not the
  /// net — the platform commission is settled from the driver wallet separately).
  double get _cashAmount {
    final raw = (trip.finalFare ?? trip.estimatedFare ?? '0').replaceAll(
      '₹',
      '',
    );
    return double.tryParse(raw.trim()) ?? 0;
  }

  String get _fare {
    final raw = trip.finalFare ?? trip.estimatedFare ?? '0';
    return raw.startsWith('₹') ? raw : '₹$raw';
  }

  void _confirmCash() =>
      ref.read(tripSessionNotifierProvider.notifier).confirmCash();

  void _maybePromptForCash() {
    if (_promptShown) return;
    final session = ref.read(tripSessionNotifierProvider);
    if (!session.needsCashCollection) return;
    _promptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CashCollectionDialog.show(
        context,
        amount: _cashAmount,
        onConfirmed: _confirmCash,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tripSessionNotifierProvider);
    final needsCash = session.needsCashCollection;
    _maybePromptForCash();

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
              if (needsCash) ...[
                const SizedBox(height: AppSpacing.md),
                _cashReminder(),
              ],
              const Spacer(),
              if (needsCash)
                PrimaryButton(
                  text: 'CONFIRM CASH COLLECTED',
                  isLoading: session.actionInProgress,
                  onPressed: session.actionInProgress ? null : _confirmCash,
                )
              else
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

  Widget _cashReminder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Collect ₹${_cashAmount.toStringAsFixed(2)} cash from the rider, '
              'then confirm below.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onBackground,
              ),
            ),
          ),
        ],
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
