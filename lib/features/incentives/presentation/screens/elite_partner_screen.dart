import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/elite_status_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../providers/incentives_providers.dart';
import '../widgets/privilege_matrix_card.dart';

class ElitePartnerScreen extends ConsumerStatefulWidget {
  const ElitePartnerScreen({super.key});

  @override
  ConsumerState<ElitePartnerScreen> createState() => _ElitePartnerScreenState();
}

class _ElitePartnerScreenState extends ConsumerState<ElitePartnerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eliteStatusNotifierProvider.notifier).fetchEliteStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eliteStatusNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'SaaradhiGo Elite',
          style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildContent(context, state)),
    );
  }

  Widget _buildContent(BuildContext context, EliteStatusState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Unable to load Elite Status',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.errorMessage ??
                    'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Retry',
                onPressed: () => ref
                    .read(eliteStatusNotifierProvider.notifier)
                    .fetchEliteStatus(),
              ),
            ],
          ),
        ),
      );
    }

    final elite = state.eliteStatus;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(eliteStatusNotifierProvider.notifier)
          .fetchEliteStatus(refresh: true),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.margin,
          vertical: AppSpacing.md,
        ),
        children: [
          // Hero Metallic Tier Card
          _buildHeroTierCard(elite),
          const SizedBox(height: AppSpacing.lg),

          // 3-Column Quality Metrics Card
          _buildQualityMetricsCard(elite),
          const SizedBox(height: AppSpacing.lg),

          // Privilege & Perks Matrix
          PrivilegeMatrixCard(currentTier: elite.tierEnum),
          const SizedBox(height: AppSpacing.xl),

          // Action Button to Incentives
          PrimaryButton(
            text: 'View Active Quests & Bonuses',
            onPressed: () => context.push('/incentives'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroTierCard(EliteStatusModel elite) {
    final accent = elite.accentColor;
    final nextTierStr = elite.nextTier ?? 'Diamond';
    final tripsRemaining = elite.tripsToNextTier ?? 40;

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.15),
                  border: Border.all(color: accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.military_tech_rounded,
                  color: accent,
                  size: 36,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE STATUS',
                      style: AppTypography.labelCaps.copyWith(
                        color: accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      elite.tierEnum.displayName,
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${elite.totalTrips} Lifetime Completed Trips',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Progression Bar to Next Tier
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next Tier: $nextTierStr',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$tripsRemaining more trips',
                      style: AppTypography.labelCaps.copyWith(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: LinearProgressIndicator(
                    value: 0.65, // Generous progress representation
                    backgroundColor: AppColors.surface,
                    color: accent,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityMetricsCard(EliteStatusModel elite) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tier Maintenance Metrics',
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetricCol(
                  title: 'Rating',
                  value: '${elite.rating}★',
                  req: 'Min 4.7★',
                  isQualified: elite.isRatingQualified,
                ),
              ),
              Container(width: 1, height: 50, color: const Color(0x1AFFFFFF)),
              Expanded(
                child: _buildMetricCol(
                  title: 'Acceptance',
                  value: elite.acceptanceRate,
                  req: 'Min 90%',
                  isQualified: elite.isAcceptanceQualified,
                ),
              ),
              Container(width: 1, height: 50, color: const Color(0x1AFFFFFF)),
              Expanded(
                child: _buildMetricCol(
                  title: 'Cancellation',
                  value: elite.cancellationRate,
                  req: 'Max 4%',
                  isQualified: elite.isCancellationQualified,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol({
    required String title,
    required String value,
    required String req,
    required bool isQualified,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.dataMono.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (isQualified ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            isQualified ? 'QUALIFIED' : 'ACTION REQ',
            style: AppTypography.labelCaps.copyWith(
              color: isQualified ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 8,
            ),
          ),
        ),
      ],
    );
  }
}
