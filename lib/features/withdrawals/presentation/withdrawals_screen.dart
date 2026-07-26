import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../domain/withdrawal.dart';
import 'withdrawal_providers.dart';

class WithdrawalsScreen extends ConsumerWidget {
  const WithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(withdrawalBalanceProvider);
    final historyAsync = ref.watch(withdrawalHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawals')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(withdrawalBalanceProvider);
          ref.invalidate(withdrawalHistoryProvider);
          await ref.read(withdrawalBalanceProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            balanceAsync.when(
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(withdrawalBalanceProvider),
              ),
              data: (balance) => _BalanceCard(balance: balance),
            ),
            const SectionHeader(title: 'Past requests'),
            historyAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(withdrawalHistoryProvider),
              ),
              data: (requests) => requests.isEmpty
                  ? const EmptyView(
                      message: 'No withdrawals yet.',
                      icon: Icons.account_balance_outlined,
                    )
                  : Column(
                      children: [
                        for (final request in requests)
                          _RequestTile(request: request),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.balance});

  final WithdrawalBalance balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.watch(withdrawalControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available to withdraw',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              Fmt.money(balance.availableBalance),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Minimum ${Fmt.moneyCompact(balance.minimumWithdrawal)} per request',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (balance.blocked) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 18, color: AppTheme.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        balance.blockRemaining == null
                            ? 'Another withdrawal is already being processed.'
                            : 'You can withdraw again in '
                                '${Fmt.duration(balance.blockRemaining!)}.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: (balance.blocked ||
                      controller.isLoading ||
                      balance.availableBalance < balance.minimumWithdrawal)
                  ? null
                  : () => _promptAmount(context, ref, balance),
              icon: controller.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.arrow_outward_rounded),
              label: const Text('Withdraw to UPI'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptAmount(
    BuildContext context,
    WidgetRef ref,
    WithdrawalBalance balance,
  ) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AmountSheet(balance: balance),
    );
    if (amount == null) return;

    final ok = await ref
        .read(withdrawalControllerProvider.notifier)
        .request(amount);

    if (!context.mounted) return;
    if (ok) {
      showInfoSnack(
        context,
        'Requested ${Fmt.money(amount)}. You will be paid once it is approved.',
      );
    } else {
      final error = ref.read(withdrawalControllerProvider).error;
      if (error != null) showErrorSnack(context, error);
    }
  }
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.balance});

  final WithdrawalBalance balance;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    if (value < widget.balance.minimumWithdrawal) {
      setState(() => _error =
          'Minimum is ${Fmt.moneyCompact(widget.balance.minimumWithdrawal)}');
      return;
    }
    if (value > widget.balance.availableBalance) {
      setState(() => _error = 'You only have '
          '${Fmt.money(widget.balance.availableBalance)} available');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How much?',
            style:
                theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              prefixText: '₹ ',
              labelText: 'Amount',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final preset in _presets())
                ActionChip(
                  label: Text(Fmt.moneyCompact(preset)),
                  onPressed: () {
                    _controller.text = preset.toStringAsFixed(0);
                    setState(() => _error = null);
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: _submit, child: const Text('Request payout')),
        ],
      ),
    );
  }

  /// Round-number shortcuts plus "everything", which is what most drivers
  /// actually want at the end of a week.
  List<double> _presets() {
    final available = widget.balance.availableBalance;
    final options = <double>[500, 1000, 2000, 5000]
        .where((v) => v <= available)
        .toList();
    if (available > 0 && !options.contains(available)) options.add(available);
    return options;
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final WithdrawalRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color;
    final IconData icon;
    if (request.isSettled) {
      color = AppTheme.brand;
      icon = Icons.check_circle_rounded;
    } else if (request.isFailed) {
      color = AppTheme.danger;
      icon = Icons.error_rounded;
    } else {
      color = AppTheme.warning;
      icon = Icons.schedule_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          Fmt.money(request.amount),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${request.explanation}\n${Fmt.dayAndTime(request.requestedAt)}',
          style: theme.textTheme.bodySmall,
        ),
        isThreeLine: true,
        trailing: StatusChip(
          label: Fmt.titleCase(request.status),
          color: color,
        ),
      ),
    );
  }
}
