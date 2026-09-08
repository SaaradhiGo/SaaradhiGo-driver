import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/theme/app_theme.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_balance_model.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_notifier.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_providers.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/widgets/withdrawal_request_bottom_sheet.dart';

class _FakeEarningsNotifier extends EarningsNotifier {
  _FakeEarningsNotifier(this.seed);
  final EarningsState seed;
  double? submittedAmount;

  @override
  EarningsState build() => seed;

  @override
  Future<bool> requestWithdrawal(double amount) async {
    submittedAmount = amount;
    return true;
  }
}

void main() {
  group('WithdrawalRequestBottomSheet', () {
    testWidgets(
      'renders balance, allows quick amount selection and submits without overflow under keyboard insets',
      (tester) async {
        final notifier = _FakeEarningsNotifier(
          const EarningsState(
            withdrawalBalance: WithdrawalBalanceModel(
              availableBalance: 8200.0,
              blocked: false,
              minimumWithdrawal: 500.0,
              feePercent: 2.5,
            ),
          ),
        );

        // Simulate mobile viewport with virtual keyboard insets
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [earningsNotifierProvider.overrideWith(() => notifier)],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(body: WithdrawalRequestBottomSheet()),
            ),
          ),
        );

        expect(find.text('Payout Withdrawal'), findsOneWidget);
        expect(find.text('₹8200.00'), findsOneWidget);

        // Tap quick amount: ₹1,000
        await tester.tap(find.text('₹1,000'));
        await tester.pump();

        // Verify input is updated
        expect(find.text('1000'), findsOneWidget);

        // Tap submit
        await tester.ensureVisible(find.text('CONFIRM WITHDRAWAL'));
        await tester.tap(find.text('CONFIRM WITHDRAWAL'));
        await tester.pump();

        expect(notifier.submittedAmount, 1000.0);
      },
    );

    testWidgets(
      'shows validation SnackBar when tapping submit with empty amount',
      (tester) async {
        final notifier = _FakeEarningsNotifier(
          const EarningsState(
            withdrawalBalance: WithdrawalBalanceModel(
              availableBalance: 5000.0,
              blocked: false,
              minimumWithdrawal: 500.0,
            ),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [earningsNotifierProvider.overrideWith(() => notifier)],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(body: WithdrawalRequestBottomSheet()),
            ),
          ),
        );

        // Empty field, tap submit
        await tester.tap(find.text('CONFIRM WITHDRAWAL'));
        await tester.pump();

        expect(find.text('Enter a valid withdrawal amount.'), findsWidgets);
        expect(notifier.submittedAmount, isNull);
      },
    );

    testWidgets('shows locked SnackBar when account is blocked', (
      tester,
    ) async {
      final notifier = _FakeEarningsNotifier(
        const EarningsState(
          withdrawalBalance: WithdrawalBalanceModel(
            availableBalance: 5000.0,
            blocked: true,
            minimumWithdrawal: 500.0,
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [earningsNotifierProvider.overrideWith(() => notifier)],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: WithdrawalRequestBottomSheet()),
          ),
        ),
      );

      expect(find.text('WITHDRAWALS LOCKED'), findsOneWidget);

      await tester.tap(find.text('WITHDRAWALS LOCKED'));
      await tester.pump();

      expect(
        find.text(
          'Withdrawals are currently locked for your account. Please contact support.',
        ),
        findsOneWidget,
      );
      expect(notifier.submittedAmount, isNull);
    });
  });
}
