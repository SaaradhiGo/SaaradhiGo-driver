import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:saaradhigo_driver/core/market/market_config.dart';
import 'package:saaradhigo_driver/core/market/market_providers.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_balance_model.dart';
import 'package:saaradhigo_driver/features/dashboard/presentation/widgets/payout_setup_banner.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_notifier.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_providers.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/payout_plan.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/screens/driver_earnings_tab.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/widgets/platform_fee_section.dart';
import 'package:saaradhigo_driver/features/requirements/requirements_api.dart';
import 'package:saaradhigo_driver/features/trip/presentation/providers/trip_providers.dart';
import 'package:saaradhigo_driver/features/trip/presentation/providers/trip_session_notifier.dart';
import 'package:saaradhigo_driver/features/trip/presentation/widgets/cancel_trip_sheet.dart';
import 'package:saaradhigo_driver/l10n/app_localizations.dart';
import 'package:saaradhigo_driver/ui/incoming_offer_card.dart';

import '../support/driver_ui_fixtures.dart';

/// Launch round 2 (16 Nov): drive before payout setup, confirm a cancel,
/// and say "No commission" rather than a red zero.

class _Earnings extends EarningsNotifier {
  @override
  EarningsState build() => const EarningsState(
    withdrawalBalance: WithdrawalBalanceModel(
      availableBalance: 820.0,
      blocked: false,
      minimumWithdrawal: 500.0,
    ),
  );
  @override
  Future<void> loadInitialData() async {}
  @override
  Future<void> refresh() async {}
}

class _Trip extends TripSessionNotifier {
  final reasons = <String?>[];
  @override
  TripSessionState build() => const TripSessionState();
  @override
  void cancelTrip({String? reason}) => reasons.add(reason);
}

Widget _scoped(List overrides, Widget child) => ProviderScope(
  overrides: [...overrides],
  child: sgApp(Scaffold(body: child)),
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('payout readiness', () {
    test('a missing ready reads as false', () {
      Requirements req(Map<String, dynamic> pm) => Requirements.fromJson({
        'config': {'country': 'IN', 'languages': <String>[]},
        'checklist': {
          'items': <Object>[],
          'done': 0,
          'total': 0,
          'blocking': <String>[],
        },
        'payout_method': pm,
      });
      expect(req({'kind': 'upi'}).payoutReady, isFalse);
      expect(req({'kind': 'upi', 'ready': true}).payoutReady, isTrue);
    });

    testWidgets('Home banner shows when not ready and opens the step', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        _scoped([
          payoutReadyProvider.overrideWith((ref) => false),
        ], PayoutSetupBanner(onOpen: () => opened++)),
      );
      expect(find.text('Set up payouts to get paid'), findsOneWidget);
      await tester.tap(find.byKey(const Key('home_payout_setup')));
      expect(opened, 1);
    });

    for (final ready in [true, null]) {
      testWidgets('Home banner hidden when ready is $ready', (tester) async {
        await tester.pumpWidget(
          _scoped([
            payoutReadyProvider.overrideWith((ref) => ready),
          ], const PayoutSetupBanner()),
        );
        expect(find.byKey(const Key('home_payout_setup')), findsNothing);
      });
    }

    for (final (ready, label) in [
      (false, 'Waiting for payout setup'),
      (true, 'Ready to withdraw'),
    ]) {
      testWidgets('Earnings balance label when ready is $ready', (
        tester,
      ) async {
        setPhoneSurface(tester);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              payoutReadyProvider.overrideWith((ref) => ready),
              earningsNotifierProvider.overrideWith(_Earnings.new),
              driverEarningsPeriodProvider.overrideWith((ref, _) async => null),
              payoutPlanProvider.overrideWith((ref) async => null),
              feePlanProvider.overrideWith((ref) async => null),
              feeNoteProvider.overrideWith((ref) async => null),
            ],
            child: sgApp(const DriverEarningsTab()),
          ),
        );
        await tester.pump();
        expect(find.text(label), findsOneWidget);
      });
    }
  });

  group('cancel confirmation', () {
    Future<_Trip> open(WidgetTester tester, {MarketConfig? market}) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      final trip = _Trip();
      await tester.pumpWidget(
        _scoped(
          [
            tripSessionNotifierProvider.overrideWith(() => trip),
            if (market != null) marketConfigProvider.overrideWithValue(market),
          ],
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showCancelTripSheet(context, ref),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return trip;
    }

    testWidgets('a reason asks first; Cancel trip then cancels', (
      tester,
    ) async {
      final trip = await open(tester);
      await tester.tap(find.text('Rider is a no-show'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this trip?'), findsOneWidget);
      expect(trip.reasons, isEmpty);
      // No market fee configured: no penalty line.
      expect(find.byKey(const Key('cancel_confirm_fee')), findsNothing);
      await tester.tap(find.byKey(const Key('cancel_confirm_yes')));
      await tester.pumpAndSettle();
      expect(trip.reasons, ['no_show']);
    });

    testWidgets('Keep trip cancels nothing', (tester) async {
      final trip = await open(tester);
      await tester.tap(find.text('Rider is a no-show'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel_confirm_keep')));
      await tester.pumpAndSettle();
      expect(trip.reasons, isEmpty);
      expect(find.text('Cancel this trip?'), findsNothing);
    });

    test('fee line follows the market policy, never for safety', () async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      final india = MarketConfig.fromData({
        'country': {
          'code': 'IN',
          'currency': {'code': 'INR', 'symbol': '₹', 'minor_units': 2},
          'cancel_policy': {
            'charges_fee': true,
            'fee_percent': '10.00',
            'fee_cap_minor': 10000,
          },
        },
      });
      expect(
        cancelFeeLine(l, india, 'personal'),
        'An unjustified cancellation can cost you 10% of the fare, up to ₹100.',
      );
      expect(cancelFeeLine(l, india, 'safety'), isNull);
      expect(cancelFeeLine(l, MarketConfig.builtIn, 'personal'), isNull);
    });
  });

  group('offer commission', () {
    Future<void> pump(WidgetTester tester, Map<String, dynamic> extra) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        sgApp(
          IncomingOfferCard(
            payload: {...sampleOffer, 'earning': '248.00', ...extra},
            alert: false,
            mapProvider: kPlaceholderMaps,
            onAccept: () {},
            onDecline: () {},
            onExpired: () {},
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('zero shows No commission, not a red minus', (tester) async {
      await pump(tester, {'commission_rate': '0', 'commission_amount': '0.00'});
      expect(find.byKey(const Key('offer_no_commission')), findsOneWidget);
      expect(find.text('No commission'), findsOneWidget);
      expect(find.byKey(const Key('offer_commission_row')), findsNothing);
    });

    testWidgets('non-zero keeps the commission row', (tester) async {
      await pump(tester, {
        'commission_rate': '20.00',
        'commission_amount': '49.56',
      });
      expect(find.byKey(const Key('offer_commission_row')), findsOneWidget);
      expect(find.byKey(const Key('offer_no_commission')), findsNothing);
    });

    test('isZeroAmount in any currency', () {
      expect(isZeroAmount('₹0'), isTrue);
      expect(isZeroAmount(r'$0.00'), isTrue);
      expect(isZeroAmount('0%'), isTrue);
      expect(isZeroAmount('₹10'), isFalse);
      expect(isZeroAmount('—'), isFalse);
    });
  });
}
