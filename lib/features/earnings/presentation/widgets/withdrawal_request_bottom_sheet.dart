import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bottom_sheet_container.dart';
import '../../../../shared/widgets/buttons.dart';
import '../providers/earnings_providers.dart';

class WithdrawalRequestBottomSheet extends ConsumerStatefulWidget {
  const WithdrawalRequestBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WithdrawalRequestBottomSheet(),
    );
  }

  @override
  ConsumerState<WithdrawalRequestBottomSheet> createState() =>
      _WithdrawalRequestBottomSheetState();
}

class _WithdrawalRequestBottomSheetState
    extends ConsumerState<WithdrawalRequestBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onQuickAmountSelected(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    _validate(amount);
  }

  void _validate(double? value) {
    final balanceState = ref.read(earningsNotifierProvider).withdrawalBalance;
    final minAmount = balanceState?.minimumWithdrawal ?? 500.0;
    final availBalance = balanceState?.availableBalance ?? 0.0;

    final amt = value ?? double.tryParse(_amountController.text) ?? 0.0;

    setState(() {
      if (amt <= 0) {
        _validationError = 'Enter a valid withdrawal amount.';
      } else if (amt < minAmount) {
        _validationError =
            'Minimum withdrawal amount is ₹${minAmount.toStringAsFixed(0)}';
      } else if (amt > availBalance) {
        _validationError =
            'Amount exceeds available balance of ₹${availBalance.toStringAsFixed(2)}';
      } else {
        _validationError = null;
      }
    });
  }

  Future<void> _submit() async {
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    _validate(amt);
    if (_validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_validationError!),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final success = await ref
        .read(earningsNotifierProvider.notifier)
        .requestWithdrawal(amt);

    if (success && mounted) {
      // Capture the messenger before popping: after `pop()` this sheet's own
      // context is deactivated, and using it for `ScaffoldMessenger.of` would
      // throw a "Looking up a deactivated widget's ancestor" error.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Withdrawal request of ₹${amt.toStringAsFixed(2)} submitted!',
            style: AppTypography.bodyMd.copyWith(color: AppColors.darkText),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(earningsNotifierProvider);
    final balance = state.withdrawalBalance;
    final availBalance = balance?.availableBalance ?? 0.0;
    final minAmount = balance?.minimumWithdrawal ?? 500.0;
    final feePercent = balance?.feePercent ?? 0.0;
    final isBlocked = balance?.blocked ?? false;

    return BottomSheetContainer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Payout Withdrawal',
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Balance Display Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'AVAILABLE WITHDRAWABLE BALANCE',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${availBalance.toStringAsFixed(2)}',
                      style: AppTypography.displayLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isBlocked) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        child: Text(
                          'Withdrawals Locked',
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick Amount Chips
              Text(
                'Select Quick Amount',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      onPressed: () => _onQuickAmountSelected(500),
                      child: Text(
                        '₹500',
                        style: AppTypography.dataMono.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      onPressed: () => _onQuickAmountSelected(1000),
                      child: Text(
                        '₹1,000',
                        style: AppTypography.dataMono.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      onPressed: () => _onQuickAmountSelected(availBalance),
                      child: Text(
                        'Max',
                        style: AppTypography.dataMono.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Custom Amount TextField
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.onBackground,
                  fontSize: 24,
                ),
                onChanged: (_) => _validate(null),
                decoration: InputDecoration(
                  labelText: 'Withdrawal Amount (₹)',
                  labelStyle: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(
                    Icons.currency_rupee,
                    color: AppColors.primary,
                  ),
                  errorText: _validationError ?? state.errorMessage,
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Note: Minimum withdrawal is ₹${minAmount.toStringAsFixed(0)}. Transfer fee is ${feePercent.toStringAsFixed(1)}%.',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Submit Button
              PrimaryButton(
                text: state.isSubmittingWithdrawal
                    ? 'PROCESSING...'
                    : (isBlocked ? 'WITHDRAWALS LOCKED' : 'CONFIRM WITHDRAWAL'),
                isLoading: state.isSubmittingWithdrawal,
                onPressed: state.isSubmittingWithdrawal
                    ? null
                    : () {
                        if (isBlocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Withdrawals are currently locked for your account. Please contact support.',
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        _submit();
                      },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
