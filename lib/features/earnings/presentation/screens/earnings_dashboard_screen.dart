import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/driver_avatar.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../domain/models/earning_model.dart';
import '../../../../domain/models/withdrawal_model.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/earnings_providers.dart';
import '../widgets/cash_collection_banner.dart';
import '../widgets/earnings_breakdown_card.dart';
import '../widgets/earnings_trend_chart.dart';
import '../widgets/withdrawal_request_bottom_sheet.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(earningsNotifierProvider);
    final profileState = ref.watch(driverProfileNotifierProvider);

    final authState = ref.watch(authNotifierProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;

    final profile = profileState.maybeWhen(
      loaded: (profile) => profile,
      orElse: () => null,
    );
    final avatarUrl = profile?.user?.avatar ?? authUser?.avatar;
    final driverName =
        profile?.user?.fullName?.trim() ?? authUser?.fullName?.trim();
    final displayName = (driverName == null || driverName.isEmpty)
        ? 'Driver Partner'
        : driverName;
    final rating = profile?.ratings;
    final isVerified = profile?.approved ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: false,
        title: InkWell(
          onTap: () => context.push('/profile'),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DriverAvatar(
                  url: avatarUrl,
                  fallbackName: displayName,
                  size: 38,
                  isVerified: isVerified,
                  onTap: () => context.push('/profile'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Earnings',
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (rating != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: AppTypography.dataMono.copyWith(
                                    color: AppColors.primaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.star,
                                  size: 11,
                                  color: AppColors.primaryContainer,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      displayName,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.onSurfaceVariant,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.errorMessage != null && state.summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
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

          // Time Segmented Filter
          GlassPanel(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildFilterChip('Today', 0, state.selectedPeriodIndex),
                _buildFilterChip('This Week', 1, state.selectedPeriodIndex),
                _buildFilterChip('This Month', 2, state.selectedPeriodIndex),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Main Earnings Summary Card
          GlassPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      state.selectedPeriodIndex == 0
                          ? 'Total Earnings (Today)'
                          : state.selectedPeriodIndex == 1
                          ? 'Total Earnings (This Week)'
                          : 'Total Earnings (This Month)',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryContainer],
                      ).createShader(bounds),
                      child: Text(
                        '₹${summary?.totalEarned ?? '0.00'}',
                        style: AppTypography.displayLg.copyWith(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Divider(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      height: 1,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${summary?.totalTrips ?? 0}',
                                style: AppTypography.dataMono.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Completed Trips',
                                style: AppTypography.labelCaps.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '6.5h',
                                style: AppTypography.dataMono.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Online Hours',
                                style: AppTypography.labelCaps.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Payout Wallet & Withdrawal CTA Card
          GlassPanel(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Withdrawable Balance',
                        style: AppTypography.labelCaps.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '₹${balance?.availableBalance.toStringAsFixed(2) ?? '0.00'}',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.darkText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: () => WithdrawalRequestBottomSheet.show(context),
                  child: Text(
                    'WITHDRAW',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Earnings Trend Line Chart
          EarningsTrendChart(
            label: state.selectedPeriodIndex == 0
                ? 'Today'
                : state.selectedPeriodIndex == 1
                ? 'This Week'
                : 'This Month',
            value: '₹${summary?.todayEarned ?? '0.00'}',
            sublabel: '${summary?.todayTrips ?? 0} Trips',
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick Stats Grid
          Row(
            children: [
              Expanded(child: _buildStatBox(Icons.speed, '₹207', 'Avg / Hour')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatBox(
                  Icons.payments,
                  '₹${summary?.todayEarned ?? '0'}',
                  'Cash',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatBox(
                  Icons.credit_card,
                  '₹${summary?.totalEarned ?? '0'}',
                  'Digital',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Breakdown Card
          EarningsBreakdownCard(
            grossFares: summary?.totalEarned ?? '0.00',
            commission: summary?.totalCommission ?? '0.00',
            netEarnings: summary?.totalEarned ?? '0.00',
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

  Widget _buildFilterChip(String label, int index, int currentIndex) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(earningsNotifierProvider.notifier).setPeriod(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryContainer.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: isSelected
                ? Border.all(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  )
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelCaps.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.dataMono.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningTile(EarningModel earning) {
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
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip #${earning.tripId ?? earning.id}',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      earning.createdAt ?? 'Completed',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '+₹${earning.netEarning}',
              style: AppTypography.dataMono.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: AppColors.secondary,
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
                      withdrawal.requestedAt ?? 'Pending',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
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
                  '-₹${withdrawal.amount}',
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
}
