import '../../../../core/market/market_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/incentive_quest_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../providers/incentives_providers.dart';
import '../providers/promo_incentives_provider.dart';
import '../widgets/promo_incentive_card.dart';
import '../widgets/circular_goal_ring.dart';
import '../widgets/quest_card.dart';
import '../widgets/quest_celebration_sheet.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

class IncentivesRewardsScreen extends ConsumerStatefulWidget {
  const IncentivesRewardsScreen({super.key});

  @override
  ConsumerState<IncentivesRewardsScreen> createState() =>
      _IncentivesRewardsScreenState();
}

class _IncentivesRewardsScreenState
    extends ConsumerState<IncentivesRewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(incentivesNotifierProvider.notifier).fetchIncentives();
      ref.read(promoIncentivesProvider.notifier).fetch();
    });
  }

  Future<void> _refresh() {
    ref.read(promoIncentivesProvider.notifier).fetch();
    return ref
        .read(incentivesNotifierProvider.notifier)
        .fetchIncentives(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incentivesNotifierProvider);
    final promo = ref.watch(promoIncentivesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Incentives',
          style: AppTypography.headlineSm.copyWith(color: AppColors.primaryText),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildContent(context, state, promo)),
    );
  }

  Widget _buildContent(
    BuildContext context,
    IncentivesState state,
    PromoIncentivesState promo,
  ) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryText),
      );
    }

    if (state.hasError && promo.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Something went wrong',
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
                    .read(incentivesNotifierProvider.notifier)
                    .fetchIncentives(),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty && promo.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _refresh(),
        color: AppColors.primaryText,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.margin),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.primaryText,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Active Quests',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'New challenges and surge quests drop regularly.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SecondaryButton(text: 'Refresh', onPressed: () => _refresh()),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(),
      color: AppColors.primaryText,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.margin,
          vertical: AppSpacing.md,
        ),
        children: [
          // The "SaaradhiGo Elite Partner" banner (it opened /elite) is hidden:
          // no API backs tier progression or privileges.
          // Live incentives from the promotions engine, exactly as the API
          // returns them.
          if (promo.items.isNotEmpty) ...[
            _buildPromoSection(promo),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (state.quests.isNotEmpty) ...[
            // Active Targets (Circular Progress Rings)
            _buildActiveTargetsSection(state),
            const SizedBox(height: AppSpacing.xl),

            // Available / Active Bonuses
            Text(
              'Available Bonuses',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (state.activeQuests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'All current quests completed! Great driving.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...state.activeQuests.map((quest) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: QuestCard(
                    quest: quest,
                    onTap: () {
                      if (quest.isCompleted) {
                        QuestCelebrationSheet.show(context, quest);
                      }
                    },
                  ),
                );
              }),

            // Completed Quests Section
            if (state.completedQuests.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Completed Quests',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...state.completedQuests.map((quest) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: QuestCard(
                    quest: quest,
                    onTap: () => QuestCelebrationSheet.show(context, quest),
                  ),
                );
              }),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Weekly Summary Footer Card
            _buildSummaryFooter(context, state),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPromoSection(PromoIncentivesState promo) {
    final now = DateTime.now();
    return Column(
      key: const Key('promo_incentives_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your incentives',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final i in promo.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: PromoIncentiveCard(incentive: i, now: now),
          ),
      ],
    );
  }

  Widget _buildActiveTargetsSection(IncentivesState state) {
    // Look up or synthesize Daily Goal and Weekly Milestone for Stitch layout
    final daily =
        state.dailyGoalQuest ??
        (state.quests.isNotEmpty
            ? state.quests.first
            : const IncentiveQuestModel(
                id: 0,
                title: 'Daily Goal',
                targetTrips: 20,
                progressTrips: 12,
              ));

    final weekly =
        state.weeklyMilestoneQuest ??
        (state.quests.length > 1
            ? state.quests[1]
            : const IncentiveQuestModel(
                id: 0,
                title: 'Weekly Milestone',
                targetTrips: 50,
                progressTrips: 15,
              ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Targets',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: CircularGoalRing(
                title: 'Daily Goal',
                valueText: '${daily.progressTrips}/${daily.targetTrips}',
                progress: daily.progressFraction,
                accentColor: AppColors.primaryText,
                onTap: () {
                  if (daily.isCompleted) {
                    QuestCelebrationSheet.show(context, daily);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: CircularGoalRing(
                title: 'Weekly Milestone',
                valueText: '${weekly.progressTrips}/${weekly.targetTrips}',
                progress: weekly.progressFraction,
                accentColor: AppColors.primaryText,
                onTap: () {
                  if (weekly.isCompleted) {
                    QuestCelebrationSheet.show(context, weekly);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryFooter(BuildContext context, IncentivesState state) {
    final formattedTotal = state.totalWeeklyEarned.toStringAsFixed(2);

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total earned this week',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Incentives & Bonuses',
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => context.push('/earnings'),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${marketSymbol()}$formattedTotal',
                    style: AppTypography.dataMono.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: SgText.size(18),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primaryText,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
