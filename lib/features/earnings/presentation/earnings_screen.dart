import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../domain/earnings.dart';
import 'earnings_providers.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(earningsSummaryProvider);
    final periodsAsync = ref.watch(earningsPeriodsProvider);
    final entriesAsync = ref.watch(earningsEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(Routes.withdrawals),
            icon: const Icon(Icons.account_balance_rounded, size: 18),
            label: const Text('Withdraw'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(earningsSummaryProvider);
          ref.invalidate(earningsEntriesProvider);
          await ref.read(earningsSummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            summaryAsync.when(
              loading: () => const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(earningsSummaryProvider),
              ),
              data: (summary) => _SummaryCard(summary: summary),
            ),
            const SectionHeader(title: 'Recent activity'),
            periodsAsync.when(
              loading: () => const SizedBox(
                height: 90,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(earningsEntriesProvider),
              ),
              data: (periods) => Column(
                children: [
                  for (final period in periods) _PeriodRow(period: period),
                ],
              ),
            ),
            const SectionHeader(title: 'Trip settlements'),
            entriesAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(earningsEntriesProvider),
              ),
              data: (entries) => entries.isEmpty
                  ? const EmptyView(
                      message:
                          'No settlements yet. Completed trips will show here.',
                      icon: Icons.receipt_long_outlined,
                    )
                  : Column(
                      children: [
                        for (final entry in entries.take(50))
                          _EntryTile(entry: entry),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lifetime earnings',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              Fmt.money(summary.totalEarned),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const Divider(height: 28),
            DetailRow(
              label: 'Platform commission (${summary.commissionPercent.toStringAsFixed(0)}%)',
              value: '− ${Fmt.money(summary.totalCommission)}',
            ),
            DetailRow(
              label: 'Net to you',
              value: Fmt.money(summary.netEarned),
            ),
            DetailRow(
              label: 'Total trips',
              value: '${summary.totalTrips}',
            ),
            DetailRow(
              // The settlement balance goes negative on cash trips; saying
              // "wallet: −₹420" without explanation reads like a bug.
              label: summary.owesPlatform
                  ? 'Commission you owe'
                  : 'Balance available',
              value: Fmt.money(summary.walletBalance.abs()),
              valueColor:
                  summary.owesPlatform ? AppTheme.warning : AppTheme.brand,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.period});

  final EarningsPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${period.trips} trips · ${Fmt.money(period.cashCollected)} in cash',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              Fmt.money(period.gross),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final EarningEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry.isCash
              ? AppTheme.warning.withValues(alpha: 0.18)
              : AppTheme.brand.withValues(alpha: 0.18),
          child: Icon(
            entry.isCash ? Icons.payments_outlined : Icons.credit_card_outlined,
            size: 18,
            color: entry.isCash ? AppTheme.warning : AppTheme.brand,
          ),
        ),
        title: Text(
          entry.tripId != null ? 'Trip #${entry.tripId}' : 'Settlement',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${Fmt.titleCase(entry.method ?? 'online')} · '
          '${Fmt.dayAndTime(entry.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          Fmt.money(entry.amount),
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
