import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../trip/domain/trip.dart';
import 'history_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterProvider);
    final historyAsync = ref.watch(tripHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ride history')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                for (final option in const [
                  (label: 'All', value: null),
                  (label: 'Completed', value: 'completed'),
                  (label: 'Cancelled', value: 'cancelled'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(option.label),
                      selected: filter == option.value,
                      onSelected: (_) => ref
                          .read(historyFilterProvider.notifier)
                          .set(option.value),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(tripHistoryProvider),
              ),
              data: (trips) => trips.isEmpty
                  ? const EmptyView(
                      message: 'No trips here yet.',
                      icon: Icons.route_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(tripHistoryProvider);
                        await ref.read(tripHistoryProvider.future);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: trips.length,
                        itemBuilder: (context, index) =>
                            _TripTile(trip: trips[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTile extends ConsumerWidget {
  const _TripTile({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cancelled = trip.status == TripStatus.cancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusChip(
                    label: cancelled ? 'Cancelled' : 'Completed',
                    color: cancelled ? AppTheme.danger : AppTheme.brand,
                  ),
                  const Spacer(),
                  Text(
                    Fmt.dayAndTime(trip.completedAt ?? trip.cancelledAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _AddressLine(
                icon: Icons.trip_origin_rounded,
                color: AppTheme.brand,
                text: trip.pickupAddress ?? 'Pickup',
              ),
              const SizedBox(height: 4),
              _AddressLine(
                icon: Icons.place_rounded,
                color: AppTheme.danger,
                text: trip.destinationAddress ?? 'Drop',
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Text(
                    '#${trip.id}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (!cancelled)
                    Text(
                      Fmt.money(trip.fareToCollect),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetail(BuildContext context, WidgetRef ref) async {
    // Receipts are issued asynchronously after completion, so the URL may not
    // exist yet for a trip that finished seconds ago.
    final url = trip.status == TripStatus.completed
        ? await ref.read(tripRepositoryProvider).receiptPdfUrl(trip.id)
        : null;

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Trip #${trip.id}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            DetailRow(label: 'Rider', value: trip.riderName ?? '—'),
            DetailRow(
              label: 'Status',
              value: Fmt.titleCase(trip.status.name),
            ),
            if (trip.cancelledBy != null)
              DetailRow(
                label: 'Cancelled by',
                value: Fmt.titleCase(trip.cancelledBy!),
              ),
            DetailRow(label: 'Fare', value: Fmt.money(trip.fareToCollect)),
            DetailRow(
              label: 'Payment',
              value: Fmt.titleCase(trip.paymentMethod ?? '—'),
            ),
            DetailRow(label: 'Pickup', value: trip.pickupAddress ?? '—'),
            DetailRow(label: 'Drop', value: trip.destinationAddress ?? '—'),
            DetailRow(label: 'Started', value: Fmt.clock(trip.startedAt)),
            DetailRow(label: 'Ended', value: Fmt.clock(trip.completedAt)),
            const SizedBox(height: 16),
            if (url != null)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Receipt available'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
