import '../../../../core/market/market_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../domain/models/earning_model.dart';
import '../../../../domain/models/withdrawal_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../incentives/presentation/providers/promo_incentives_provider.dart';
import '../providers/earnings_providers.dart';
import '../widgets/cash_collection_banner.dart';
import '../widgets/earning_trip_tile.dart';
import '../widgets/earnings_breakdown_card.dart';
import '../earnings_display.dart';
import '../widgets/withdrawal_request_bottom_sheet.dart';
import '../providers/tier3_providers.dart';
import '../../../../ui/driver_f_logic.dart';
import '../../../../ui/driver_earnings_view.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_tokens.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

/// Financials (Earnings & Wallet) Dashboard Screen (`/earnings`).
class EarningsDashboardScreen extends ConsumerStatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  ConsumerState<EarningsDashboardScreen> createState() =>
      _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState
    extends ConsumerState<EarningsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(earningsNotifierProvider.notifier).loadInitialData();
      ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
      ref.read(promoIncentivesProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(earningsNotifierProvider);

    // Auto-retry a failed/stale load when connectivity returns
    // (docs/14_ERROR_HANDLING.md:11 "Auto-retry queued HTTP requests"). Only
    // fires when there is an error on screen or nothing loaded yet — a healthy
    // dashboard is never spammed by a redundant refresh.
    ref.listen<bool>(isOnlineNetworkProvider, (previous, next) {
      if (previous == true || next != true) return;
      final current = ref.read(earningsNotifierProvider);
      if (current.isLoading) return;
      final notifier = ref.read(earningsNotifierProvider.notifier);
      if (current.summary == null) {
        // Nothing rendered yet — a full first load (with spinner) is honest.
        notifier.loadInitialData();
      } else if (current.errorMessage != null) {
        // Data on screen but a section failed — a gentle background refresh.
        notifier.refresh();
      }
    });

    return Scaffold(
      backgroundColor: SgColors.bg000,
      appBar: AppBar(title: Text(sgL10n(context).earnTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.onBackground,
          backgroundColor: AppColors.surfaceContainer,
          onRefresh: () async {
            await Future.wait([
              ref.read(earningsNotifierProvider.notifier).refresh(),
              ref.read(driverProfileNotifierProvider.notifier).fetchProfile(),
            ]);
          },
          child: _buildBody(state),
        ),
      ),
    );
  }

  Widget _buildBody(EarningsState state) {
    if (state.isLoading && state.summary == null) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.onBackground),
      );
    }

    if (state.errorMessage != null && state.summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Unable to load financial data',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'RETRY',
                onPressed: () {
                  ref.read(earningsNotifierProvider.notifier).loadInitialData();
                },
              ),
            ],
          ),
        ),
      );
    }

    final summary = state.summary;
    final balance = state.withdrawalBalance;

    // Every figure below is derived from real EarningsSummaryModel fields:
    // net = gross fares − platform commission; avg/trip = net ÷ completed trips.
    // Commission is shown exactly as the API returned it; a missing value hides
    // its line (and the figures that depend on it) instead of showing a default.
    // The selected tab's own figures: today from the summary's today_* fields,
    // week and month summed from the daily series. Never the all-time totals
    // under a period label (the Today tab showed every trip ever).
    final days = ref.watch(dailyEarningsProvider).value;
    final period = periodFigures(
      state.selectedPeriodIndex,
      todayTrips: summary?.todayTrips,
      todayNet: summary?.todayNet,
      todayCommission: summary?.todayCommission,
      todayGross: summary?.todayEarned,
      days: days,
    );
    final commission = period?.commission;
    final net =
        period?.net ?? netFromGrossAndCommission(period?.gross, commission);
    final trips = period?.trips ?? 0;
    final l = sgL10n(context);
    final rateLabel = commissionRateLabel(
      summary?.commissionPercent,
      mixed: summary?.commissionPercentMixed,
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.margin,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cash Collection Prompt Banner if active
          if (state.cashToCollect != null && state.cashToCollect! > 0) ...[
            CashCollectionBanner(
              amount: state.cashToCollect!,
              onDismiss: () {
                ref
                    .read(earningsNotifierProvider.notifier)
                    .setCashToCollect(null);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          EarningsPeriodTabs(
            selected: state.selectedPeriodIndex,
            onSelect: (i) =>
                ref.read(earningsNotifierProvider.notifier).setPeriod(i),
          ),
          const SizedBox(height: AppSpacing.md),

          // The period's figure on a noir panel: net when the API sends it.
          EarningsNoirPanel(
            periodLabel: [
              l.earnPeriodToday,
              l.earnPeriodWeek,
              l.earnPeriodMonth,
            ][state.selectedPeriodIndex.clamp(0, 2)],
            trips: trips,
            amount: summaryMoney(net ?? period?.gross),
            isNet: net != null,
            commission: commission == null ? null : summaryMoney(commission),
            commissionRate: rateLabel,
          ),
          const SizedBox(height: AppSpacing.md),

          // The 7-day chart from the daily endpoint; hidden when it fails.
          if (days != null && days.isNotEmpty) ...[
            EarningsWeekChart(
              days: days.length > 7 ? days.sublist(days.length - 7) : days,
              money: (v) => summaryMoney(v.toStringAsFixed(2)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Breakdown Card
          EarningsBreakdownCard(
            grossFares: period?.gross ?? '0.00',
            commission: commission,
            commissionRate: rateLabel,
            netEarnings: net,
            promoPaid: summary?.promoPaidByPlatform,
            promoPaidToday: summary?.todayPromoPaidByPlatform,
            promoPaidLabel: summary?.promoPaidLabel,
            incentiveRewards: summary?.incentiveRewards,
            referralRewards: summary?.referralRewards,
            incentiveCommission: summary?.incentiveCommission,
            incentiveTax: summary?.incentiveTax,
            taxCollected: summary?.taxCollected,
            taxCollectedLabel: summary?.taxCollectedLabel,
            regulatoryFees: summary?.regulatoryFeesCollected,
            rewardsPendingReview: summary?.rewardsPendingReview,
            rewardsPendingReviewLabel: summary?.rewardsPendingReviewLabel,
            rewardRecovery: summary?.rewardRecovery,
            rewardRecoveryLabel: summary?.rewardRecoveryLabel,
            rewardRecoveryRemaining: summary?.rewardRecoveryRemaining,
          ),
          const SizedBox(height: AppSpacing.md),


          // TODO(data): cash in hand. The summary model carries no
          // cash_collected yet, so the breakdown has no cash line.

          // Withdrawable and the 64px Withdraw; blocked with its reason when
          // payout details are missing.
          WithdrawPanel(
            balance: exactBalance(
              balance?.availableBalance,
              balance?.currency,
            ),
            canWithdraw: (balance?.availableBalance ?? 0) > 0,
            payoutMissing: ref.watch(payoutDetailsOnFileProvider).value == false,
            onWithdraw: () => WithdrawalRequestBottomSheet.show(context),
            onAddPayout: () => context.push('/onboarding/photo-bank'),
          ),
          const SizedBox(height: AppSpacing.md),

          // Incentives & Quests Bento Card
          InkWell(
            onTap: () => context.push('/incentives'),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.onBackground,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Incentives & Quests',
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.onBackground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                              ),
                              child: Text(
                                'BONUS',
                                style: AppTypography.labelCaps.copyWith(
                                  color: AppColors.onBackground,
                                  fontSize: SgText.size(13),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          incentivesCardSummary(
                                ref.watch(promoIncentivesProvider),
                                DateTime.now(),
                              ) ??
                              'Complete ride milestones & unlock weekly cash bonuses',
                          key: const Key('incentives_card_summary'),
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: SgText.size(13),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Recent Transactions & Withdrawals History
          Text(
            'Recent Transactions',
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.earningsList.isEmpty && state.withdrawalHistory.isEmpty)
            GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'No transaction history found.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else ...[
            ...state.withdrawalHistory.map((w) => _buildWithdrawalTile(w)),
            ...state.earningsList.map((e) => _buildEarningTile(e)),
          ],

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildEarningTile(EarningModel earning) => EarningTripTile(
    earning: earning,
    timestamp: _formatTimestamp(earning.createdAt),
  );

  Widget _buildWithdrawalTile(WithdrawalModel withdrawal) {
    final isSuccess =
        withdrawal.status == 'approved' || withdrawal.status == 'completed';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: AppColors.primaryText,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payout Withdrawal',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(withdrawal.requestedAt) ?? 'Pending',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: SgText.size(13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${marketSymbol()}${withdrawal.amount}',
                  style: AppTypography.dataMono.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                StatusBadge(
                  text: withdrawal.status.toUpperCase(),
                  status: isSuccess ? BadgeStatus.success : BadgeStatus.pending,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Formats an ISO-8601 timestamp (e.g. `2025-01-15T10:30:00.000Z`) for the
  /// compact transaction tiles, without an `intl` dependency. Returns null for
  /// null/empty/unparseable input so callers can fall back to a label.
  String? _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[local.month - 1];
    final day = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$day $month, $hh:$mm';
  }
}

/// Money the driver can take out is shown exactly: "₹1,240" or "₹12.40".
String exactBalance(double? amount, String? currency) =>
    ledgerMoney('${amount ?? 0}', symbol: symbolFor(currency));
