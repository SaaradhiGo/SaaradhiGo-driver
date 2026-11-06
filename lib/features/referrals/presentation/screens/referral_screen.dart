import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/referral_models.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../earnings/presentation/earnings_display.dart';
import '../providers/referral_provider.dart';

/// What a driver shares. The API supplies the code and the offer, never a
/// ready-made message, so this is a neutral line built from them.
String driverReferralShareText(ReferralMine mine) {
  final base =
      'Drive with SaaradhiGo. Use my referral code ${mine.code} when you sign up.';
  return base;
}

/// Refer & Earn for drivers (`/refer`): the code, the offer and progress.
class DriverReferralScreen extends ConsumerWidget {
  const DriverReferralScreen({super.key, this.shareOverride});

  /// Injected by tests; the app opens the system share sheet.
  final Future<void> Function(String text)? shareOverride;

  Future<void> _share(BuildContext context, ReferralMine mine) async {
    final text = driverReferralShareText(mine);
    try {
      if (shareOverride != null) {
        await shareOverride!(text);
      } else {
        await SharePlus.instance.share(ShareParams(text: text));
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied. Paste it into any chat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(referralMineProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Refer & Earn',
          style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, _) => _failed(ref),
          data: (mine) => mine == null ? _failed(ref) : _content(context, mine),
        ),
      ),
    );
  }

  Widget _failed(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "We couldn't load your referral details.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'Try again',
              onPressed: () => ref.invalidate(referralMineProvider),
            ),
          ],
        ),
      ),
    );
  }

  String _offerLine(ReferralOffer offer) {
    final trips = offer.requiredTrips;
    final tripsPart = trips > 0
        ? 'completes $trips ${trips == 1 ? 'trip' : 'trips'}'
        : 'starts driving';
    final mine = offer.referrerRewardMinor > 0 ? offer.referrerReward : null;
    final theirs = offer.refereeRewardMinor > 0 ? offer.refereeReward : null;
    if (mine != null && theirs != null) {
      return 'When a driver you refer $tripsPart, you get $mine and they get $theirs.';
    }
    if (mine != null) {
      return 'When a driver you refer $tripsPart, you get $mine.';
    }
    if (theirs != null) {
      return 'When a driver you refer $tripsPart, they get $theirs.';
    }
    return 'Refer other drivers to SaaradhiGo with your code.';
  }

  Widget _content(BuildContext context, ReferralMine mine) {
    final offer = mine.offer;
    final earned = mine.earnedMinorByCurrency.entries
        .where((e) => e.value > 0)
        .map((e) => formatMinor(e.value, e.key))
        .whereType<String>()
        .join(' + ');
    final pending = mine.pendingMinorByCurrency.entries
        .map((e) => formatMinor(e.value, e.key))
        .whereType<String>()
        .join(' + ');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.margin),
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Column(
            children: [
              Text(
                'Your referral code',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                mine.code,
                key: const Key('referral_code'),
                style: AppTypography.dataMono.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Copy',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: mine.code));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Referral code copied')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Share',
                      onPressed: () => _share(context, mine),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (offer != null) ...[
          Text(
            _offerLine(offer),
            key: const Key('referral_offer'),
            style: AppTypography.bodyMd.copyWith(color: AppColors.onBackground),
          ),
          if (offer.referrerRewardMinor > 0) ...[
            const SizedBox(height: 4),
            Text(
              key: const Key('referral_reward_note'),
              rewardNote(commission: 'none', tax: 'not configured'),
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ] else
          Text(
            'There is no referral offer running right now. Your code stays the same and will work when one starts.',
            key: const Key('referral_no_offer'),
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        if (mine.attachedTo != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _attachedLine(mine.attachedTo!),
            key: const Key('referral_attached'),
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Your referrals',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _stat('Referred', '${mine.invites}'),
            const SizedBox(width: AppSpacing.sm),
            _stat('Completed trips', '${mine.qualifiedCount}'),
            const SizedBox(width: AppSpacing.sm),
            _stat(
              'Pending review',
              '${mine.pendingReviewCount}',
              key: const Key('referral_pending_count'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          earned.isNotEmpty
              ? 'Rewards earned: $earned'
              : 'No rewards earned yet',
          key: const Key('referral_earned'),
          style: AppTypography.bodyMd.copyWith(
            color: earned.isNotEmpty
                ? AppColors.onBackground
                : AppColors.onSurfaceVariant,
            fontWeight: earned.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Pending review: $pending',
            key: const Key('referral_pending_amount'),
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (mine.referrals.isEmpty)
          Text(
            'Nobody has used your code yet. Share it to get started.',
            key: const Key('referral_empty'),
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          )
        else
          ...mine.referrals.map(_row),
      ],
    );
  }

  String _attachedLine(ReferralAttachedTo a) {
    if (a.status == 'under review') {
      return 'You joined with a referral code. Your reward is pending review.';
    }
    if (a.requiredTrips > 0) {
      return 'You joined with a referral code: ${a.tripsCompleted} of ${a.requiredTrips} trips done.';
    }
    return 'You joined with a referral code.';
  }

  Widget _stat(String label, String value, {Key? key}) {
    return Expanded(
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Column(
          children: [
            Text(
              value,
              key: key,
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(ReferralRow r) {
    final String label;
    if (r.pendingReview) {
      label = 'Pending review';
    } else if (r.status == 'rewarded') {
      label = r.rewardMinor > 0
          ? 'Reward earned: ${formatMinor(r.rewardMinor, r.currency)}'
          : 'Completed';
    } else if (r.status == 'qualified') {
      label = 'Reward on its way';
    } else {
      label = r.requiredTrips > 0
          ? '${r.tripsCompleted} of ${r.requiredTrips} trips'
          : 'Joined';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Row(
          children: [
            Expanded(
              child: Text(
                r.who,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: r.pendingReview
                    ? AppColors.secondary
                    : AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
