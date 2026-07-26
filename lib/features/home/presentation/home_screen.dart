import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/location/location_service.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dispatch/presentation/dispatch_controller.dart';
import '../../dispatch/presentation/ride_offer_sheet.dart';
import '../../duty/presentation/duty_controller.dart';
import '../../earnings/presentation/earnings_providers.dart';
import '../../profile/domain/driver_profile.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../trip/presentation/trip_controller.dart';
import 'widgets/duty_toggle.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final duty = ref.watch(dutyControllerProvider);
    final profileAsync = ref.watch(driverProfileProvider);
    final summaryAsync = ref.watch(earningsSummaryProvider);
    final auth = ref.watch(authControllerProvider);

    // A live trip always wins over the home screen. This covers the case
    // where a trip arrives by push while home is showing.
    ref.listen(tripControllerProvider, (previous, next) {
      if (next.hasTrip && !(previous?.hasTrip ?? false)) {
        context.go(Routes.activeTrip);
      }
    });

    // Present an incoming offer as a modal sheet.
    ref.listen(dispatchControllerProvider, (previous, next) {
      final hadOffer = previous?.hasOffer ?? false;
      if (next.hasOffer && !hadOffer) {
        _showOfferSheet();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auth.user?.displayName ?? 'Driver',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            profileAsync.maybeWhen(
              data: (p) => Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    p.rating.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${p.totalTrips} trips',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Safety',
            icon: const Icon(Icons.shield_outlined),
            onPressed: () => context.push(Routes.safety),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(Routes.profile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(driverProfileProvider);
          ref.invalidate(earningsSummaryProvider);
          await ref.read(earningsSummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            profileAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingView(),
              ),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(driverProfileProvider),
              ),
              data: (profile) => _DutySection(profile: profile, duty: duty),
            ),
            const SectionHeader(title: 'Today'),
            summaryAsync.when(
              loading: () => const _StatSkeleton(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(earningsSummaryProvider),
              ),
              data: (summary) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: "Today's earnings",
                          value: Fmt.money(summary.todayEarned),
                          icon: Icons.payments_outlined,
                          emphasis: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: 'Trips today',
                          value: '${summary.todayTrips}',
                          icon: Icons.route_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          // Negative when the driver holds cash and owes the
                          // platform its commission — labelled so it does not
                          // read as "we owe you minus ₹400".
                          label: summary.owesPlatform
                              ? 'Commission due'
                              : 'Wallet balance',
                          value: Fmt.money(summary.walletBalance.abs()),
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: 'Lifetime trips',
                          value: '${summary.totalTrips}',
                          icon: Icons.emoji_events_outlined,
                        ),
                      ),
                    ],
                  ),
                  if (summary.owesPlatform) ...[
                    const SizedBox(height: 12),
                    _InfoBanner(
                      icon: Icons.info_outline_rounded,
                      color: AppTheme.warning,
                      message:
                          'You have collected cash on recent trips. '
                          '${Fmt.money(summary.walletBalance.abs())} of '
                          'commission will be adjusted against your next '
                          'online earnings.',
                    ),
                  ],
                ],
              ),
            ),
            const SectionHeader(title: 'Quick actions'),
            _ActionGrid(
              onEarnings: () => context.push(Routes.earnings),
              onWithdrawals: () => context.push(Routes.withdrawals),
              onHistory: () => context.push(Routes.history),
              onSettings: () => context.push(Routes.settings),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RideOfferSheet(),
    );
  }
}

/// Toggle + status + whatever is currently stopping the driver working.
class _DutySection extends ConsumerWidget {
  const _DutySection({required this.profile, required this.duty});

  final DriverProfile profile;
  final DutyState duty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocking = profile.blockingReason;

    return Column(
      children: [
        DutyToggle(
          isOnline: duty.isOnline,
          isBusy: duty.isBusy,
          isReconnecting: duty.status == DutyStatus.reconnecting,
          enabled: blocking == null,
          onChanged: (value) async {
            final controller = ref.read(dutyControllerProvider.notifier);
            if (value) {
              await controller.goOnline();
            } else {
              await controller.goOffline();
            }
            if (!context.mounted) return;
            final error = ref.read(dutyControllerProvider).error;
            if (error != null) showErrorSnack(context, error);
          },
        ),
        if (blocking != null) ...[
          const SizedBox(height: 12),
          _InfoBanner(
            icon: profile.kycState == KycState.blocked
                ? Icons.block_rounded
                : Icons.hourglass_top_rounded,
            color: profile.kycState == KycState.blocked
                ? AppTheme.danger
                : AppTheme.warning,
            message: blocking,
          ),
        ],
        if (duty.denial != null) ...[
          const SizedBox(height: 12),
          _PermissionBanner(denial: duty.denial!),
        ],
      ],
    );
  }
}

class _PermissionBanner extends ConsumerWidget {
  const _PermissionBanner({required this.denial});

  final LocationDenial denial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(locationServiceProvider);
    final isService = denial == LocationDenial.serviceDisabled;

    return Card(
      color: AppTheme.danger.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppTheme.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isService
                    ? 'Location is switched off. Turn on GPS to receive rides.'
                    : 'Location permission is required to receive rides.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => isService
                  ? service.openLocationSettings()
                  : service.openSystemSettings(),
              child: const Text('Fix'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.onEarnings,
    required this.onWithdrawals,
    required this.onHistory,
    required this.onSettings,
  });

  final VoidCallback onEarnings;
  final VoidCallback onWithdrawals;
  final VoidCallback onHistory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (icon: Icons.bar_chart_rounded, label: 'Earnings', onTap: onEarnings),
      (
        icon: Icons.account_balance_rounded,
        label: 'Withdraw',
        onTap: onWithdrawals
      ),
      (icon: Icons.history_rounded, label: 'Ride history', onTap: onHistory),
      (icon: Icons.settings_rounded, label: 'Settings', onTap: onSettings),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        for (final item in items)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(item.icon,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
