import '../../../../core/market/market_format.dart';
import '../../../../core/market/market_config_store.dart';
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
import '../../../earnings/presentation/earnings_display.dart';
import '../../domain/support_end.dart';
import '../providers/support_end_provider.dart';
import '../providers/trip_providers.dart';
import '../widgets/rate_passenger_sheet.dart';

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
  bool _rated = false;

  Future<void> _ratePassenger() async {
    final rated = await showRatePassengerSheet(
      context,
      tripId: trip.id,
      riderName: trip.riderName,
    );
    if (!mounted) return;
    if (rated) {
      setState(() => _rated = true);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('Thanks — rating saved.')));
    }
  }

  TripModel get trip => widget.trip;

  /// Full client fare the rider pays in cash (driver collects the gross, not the
  /// net — the platform commission is settled from the driver wallet separately).
  double get _cashAmount {
    // `rider_payable` is what the rider pays when a promo held on the trip (the
    // fare less the discount SaaradhiGo pays); otherwise the fare, as before.
    final raw = MarketConfigStore.instance.current.stripSymbol(
      trip.riderPayable ?? trip.finalFare ?? trip.estimatedFare ?? '0',
    );
    return double.tryParse(raw) ?? 0;
  }

  String get _fare {
    final raw = trip.finalFare ?? trip.estimatedFare ?? '0';
    return MarketConfigStore.instance.current.withSymbol(raw);
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
    final endedBySupport = session.endedBySupport;
    final platformPaid = trip.paymentStatus == 'waived';
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
                endedBySupport ? kSupportEndedTitle : 'Trip Completed',
                key: const Key('summary_title'),
                textAlign: TextAlign.center,
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (endedBySupport && platformPaid)
                Text(
                  kSupportEndedPlatformPaid,
                  key: const Key('summary_platform_paid'),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  endedBySupport
                      ? 'Fare for the distance driven'
                      : 'You earned for this ride',
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
              if (isPositiveAmount(trip.promoDiscount)) ...[
                const SizedBox(height: AppSpacing.md),
                _promoPaidLine(),
              ],
              if (endedBySupport) ...[
                const SizedBox(height: AppSpacing.md),
                _supportEarnings(),
              ],
              if (needsCash) ...[
                const SizedBox(height: AppSpacing.md),
                _cashReminder(),
              ],
              const Spacer(),
              // Rating the passenger. The only record that a rider was
              // abusive or kept the driver waiting, and the input an
              // operator needs to act on a pattern. Offered as an action
              // rather than a modal: a driver with the next ride waiting
              // must not be held on this screen.
              if (!_rated)
                SecondaryButton(
                  text: 'RATE PASSENGER',
                  onPressed: _ratePassenger,
                ),
              if (!_rated) const SizedBox(height: AppSpacing.sm),
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

  /// A rider promo SaaradhiGo paid on this trip: its own line, not the
  /// driver's earnings and not something the rider owes in cash.
  Widget _promoPaidLine() {
    return GlassPanel(
      key: const Key('summary_promo_paid'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Promo paid by SaaradhiGo',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onBackground,
              ),
            ),
          ),
          Text(
            '${marketSymbol()}${trip.promoDiscount}',
            style: AppTypography.dataMono.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// What the driver earned on a trip support ended, as the API says it.
  Widget _supportEarnings() {
    final info = ref.watch(supportEndInfoProvider(trip.id));
    final data = info.asData?.value;
    final earning = data?.earning;
    final notice = data?.notice;
    String body;
    if (earning?.netEarning != null) {
      body =
          'You earned ${marketSymbol()}${earning!.netEarning} for the '
          'distance driven.';
    } else if (notice != null) {
      body = notice;
    } else if (info.isLoading) {
      body = 'Working out what you earned...';
    } else {
      body = 'Your earnings for this trip will show in your earnings list.';
    }
    return GlassPanel(
      key: const Key('summary_support_earnings'),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              body,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onBackground,
              ),
            ),
          ),
        ],
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
              'Collect ${marketSymbol()}${_cashAmount.toStringAsFixed(2)} cash from the rider, '
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
