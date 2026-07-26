import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../earnings/presentation/earnings_providers.dart';
import 'trip_controller.dart';

/// Post-trip: collect payment, then release the driver back to dispatch.
///
/// Cash is the one case where the driver has to do something physical, so it
/// gets an explicit confirmation button. Online and wallet trips are already
/// settled by the time we get here — the server creates the payment record on
/// completion and the rider pays through their own app — so this screen just
/// reports the outcome.
class TripSummaryScreen extends ConsumerWidget {
  const TripSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripControllerProvider);
    final trip = state.trip;
    final theme = Theme.of(context);

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip complete')),
        body: EmptyView(
          message: 'This trip has been closed.',
          icon: Icons.check_circle_outline_rounded,
          action: FilledButton(
            onPressed: () => context.go(Routes.home),
            child: const Text('Back to home'),
          ),
        ),
      );
    }

    final needsCash = trip.isCash && !trip.isPaid;

    return PopScope(
      // Leaving before settling would strand the trip on screen next launch.
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trip complete'),
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppTheme.brand,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    Fmt.money(trip.fareToCollect),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    needsCash
                        ? 'Collect this amount in cash'
                        : 'Paid by the rider',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DetailRow(label: 'Trip', value: '#${trip.id}'),
                    DetailRow(
                      label: 'Rider',
                      value: trip.riderName ?? '—',
                    ),
                    DetailRow(
                      label: 'Payment method',
                      value: Fmt.titleCase(trip.paymentMethod ?? 'deferred'),
                    ),
                    DetailRow(
                      label: 'Payment status',
                      value: Fmt.titleCase(trip.paymentStatus ?? 'pending'),
                      valueColor: trip.isPaid ? AppTheme.brand : AppTheme.warning,
                    ),
                    DetailRow(
                      label: 'Started',
                      value: Fmt.clock(trip.startedAt),
                    ),
                    DetailRow(
                      label: 'Completed',
                      value: Fmt.clock(trip.completedAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (needsCash)
              FilledButton.icon(
                onPressed: state.isBusy
                    ? null
                    : () async {
                        await ref
                            .read(tripControllerProvider.notifier)
                            .confirmCash();
                      },
                icon: const Icon(Icons.payments_rounded),
                label: Text('Cash of ${Fmt.money(trip.fareToCollect)} received'),
              )
            else
              FilledButton(
                onPressed: () => _finish(context, ref),
                child: const Text('Done'),
              ),
            if (needsCash && trip.isPaid) ...[
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => _finish(context, ref),
                child: const Text('Done'),
              ),
            ],
            if (needsCash) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _finish(context, ref),
                child: const Text('Settle later'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    await ref.read(tripControllerProvider.notifier).clearTrip();
    // The trip just moved money; the home screen's figures are stale.
    ref.invalidate(earningsSummaryProvider);
    if (context.mounted) context.go(Routes.home);
  }
}
