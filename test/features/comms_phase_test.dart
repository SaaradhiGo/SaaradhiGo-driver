/// App catch-up phase 4 (comms and fraud messages), driver: D5 and D8.
///
/// Payloads are the shapes the backend returns:
/// * GET/PUT /api/v1/notifications/preferences/ -- servers/notifications/app_views.py
///   and tests/test_notifications_console.py::TestPreferencesApi;
/// * GET /api/v1/driver/earnings/summary/ -- servers/fraud/money.py::driver_money_lines
///   (`rewards_pending_review`, `reward_recovery`, `reward_recovery_remaining`
///   and their labels) via servers/promotions/incentives.py::incentive_lines;
/// * GET /api/v1/promotions/driver/incentives/ -- `reward_status` and
///   `reward_status_label` on a held reward (tests/test_fraud_money_holds.py);
/// * POST /api/v1/driver/withdrawals/request/ -- 400 `PAYOUT_ON_HOLD`
///   (tests/test_fraud_money_payout_hold.py).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/theme/app_theme.dart';
import 'package:saaradhigo_driver/domain/models/earning_model.dart';
import 'package:saaradhigo_driver/domain/models/earnings_summary_model.dart';
import 'package:saaradhigo_driver/domain/models/notification_prefs.dart';
import 'package:saaradhigo_driver/domain/models/promo_incentive_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_balance_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_block_status_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_model.dart';
import 'package:saaradhigo_driver/features/earnings/domain/repositories/earnings_repository.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_notifier.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_providers.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/widgets/earnings_breakdown_card.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/widgets/withdrawal_request_bottom_sheet.dart';
import 'package:saaradhigo_driver/features/incentives/presentation/widgets/promo_incentive_card.dart';
import 'package:saaradhigo_driver/features/notifications/presentation/providers/notification_preferences_provider.dart';
import 'package:saaradhigo_driver/features/notifications/presentation/screens/notification_preferences_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/money_fixtures.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// The default `effective` map for a driver with no rows (servers/notifications/
/// preferences.py DEFAULT_ON and locked_on).
Map<String, dynamic> prefsPayload({bool whatsapp = true}) => {
  'effective': {
    'sms': {'transactional': true, 'promotional': false},
    'email': {'transactional': true, 'promotional': false},
    'push': {'transactional': true, 'promotional': false},
    'in_app': {'transactional': true, 'promotional': false},
    if (whatsapp) 'whatsapp': {'transactional': false, 'promotional': false},
  },
  'locked': [
    {'channel': 'in_app', 'category': 'transactional'},
  ],
  'rows': <Object>[],
};

Map<String, dynamic> summaryHeld() => {
  ...summaryNothingNew(),
  'rewards_pending_review': '300.00',
  'rewards_pending_review_label': 'Pending review',
};

Map<String, dynamic> summaryRecovered() => {
  ...summaryNothingNew(),
  'reward_recovery': '150.00',
  'reward_recovery_label': 'Recovery of reward (reviewed)',
  'reward_recovery_remaining': '300.00',
};

Map<String, dynamic> heldIncentiveRow() => {
  'id': 11,
  'name': 'Weekend 3',
  'description': 'Weekend supply push',
  'state': 'live',
  'target_trips': 3,
  'progress_trips': 3,
  'status': 'completed',
  'reward_minor': 30000,
  'currency': 'INR',
  'reward': '₹300.00',
  'starts_at': '2026-11-01T00:00:00+00:00',
  'ends_at': '2026-12-01T00:00:00+00:00',
  'filters': <String, dynamic>{},
  'budget_used_up': false,
  'reward_status': 'pending_review',
  'reward_status_label': 'Pending review',
  'commission': 'none',
  'tax': 'not configured',
};

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _PrefsAdapter implements HttpClientAdapter {
  _PrefsAdapter({Map<String, dynamic>? initial, this.putStatus = 200})
    : current = initial ?? prefsPayload();

  Map<String, dynamic> current;
  int putStatus;
  final requests = <RequestOptions>[];

  Iterable<RequestOptions> get puts => requests.where((r) => r.method == 'PUT');

  ResponseBody _body(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.method == 'GET') {
      return _body({'status': 'success', 'data': current}, 200);
    }
    if (putStatus != 200) {
      return _body({
        'status': 'error',
        'error': {'code': 'SERVER_ERROR', 'message': 'x'},
      }, putStatus);
    }
    final eff = (current['effective'] as Map).map(
      (k, v) => MapEntry(k as String, Map<String, dynamic>.from(v as Map)),
    );
    final data = options.data as Map;
    for (final p in data['preferences'] as List) {
      eff[p['channel']]![p['category']] = p['opted_in'];
    }
    current = {...current, 'effective': eff};
    return _body({'status': 'success', 'data': current}, 200);
  }

  @override
  void close({bool force = false}) {}
}

NotificationPreferencesService _service(_PrefsAdapter adapter) =>
    NotificationPreferencesService(
      Dio(BaseOptions(baseUrl: 'https://qa.example.test/api/v1/'))
        ..httpClientAdapter = adapter,
    );

Future<void> _pumpPrefs(WidgetTester tester, _PrefsAdapter adapter) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(const Size(412, 915));
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationPreferencesServiceProvider.overrideWithValue(
          _service(adapter),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const NotificationPreferencesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Switch _switchOf(WidgetTester tester, String key) => tester.widget<Switch>(
  find.descendant(of: find.byKey(Key(key)), matching: find.byType(Switch)),
);

/// A repository whose withdrawal request is refused by the API, as a Dio
/// error carrying the backend's envelope.
class _HoldRepo implements EarningsRepository {
  _HoldRepo(this.code, this.message);
  final String code;
  final String message;

  @override
  Future<WithdrawalModel> requestWithdrawal(double amount) async {
    final options = RequestOptions(path: '/driver/withdrawals/request/');
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: 400,
        data: {
          'status': 'error',
          'error': {
            'code': code,
            'message': message,
            'field': 'withdrawal',
            'issue': 'Payouts on hold',
          },
        },
      ),
    );
  }

  @override
  Future<EarningsSummaryModel> getEarningsSummary({
    String period = 'today',
  }) async => const EarningsSummaryModel();

  @override
  Future<List<EarningModel>> getEarningsList({
    int page = 1,
    int pageSize = 20,
  }) async => const [];

  @override
  Future<WithdrawalBalanceModel> getWithdrawalBalance() async =>
      const WithdrawalBalanceModel(
        availableBalance: 1200.0,
        blocked: false,
        minimumWithdrawal: 500.0,
        currency: 'INR',
      );

  @override
  Future<List<WithdrawalModel>> getWithdrawalHistory({
    int page = 1,
    int pageSize = 20,
  }) async => const [];

  @override
  Future<WithdrawalBlockStatusModel> getWithdrawalBlockStatus() async =>
      const WithdrawalBlockStatusModel(blocked: false);
}

const _heldMessageFromApi =
    'Your payouts are on hold right now. Please contact support.';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

EarningsBreakdownCard _card(Map<String, dynamic> json) {
  final s = EarningsSummaryModel.fromJson(json);
  return EarningsBreakdownCard(
    grossFares: s.totalEarned,
    commission: s.totalCommission,
    netEarnings: s.totalNet,
    incentiveRewards: s.incentiveRewards,
    referralRewards: s.referralRewards,
    incentiveCommission: s.incentiveCommission,
    incentiveTax: s.incentiveTax,
    rewardsPendingReview: s.rewardsPendingReview,
    rewardsPendingReviewLabel: s.rewardsPendingReviewLabel,
    rewardRecovery: s.rewardRecovery,
    rewardRecoveryLabel: s.rewardRecoveryLabel,
    rewardRecoveryRemaining: s.rewardRecoveryRemaining,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('D5 notification preferences', () {
    test('the payload is read as the API sends it', () {
      final p = NotificationPrefs.fromData(prefsPayload())!;
      expect(p.value('sms', 'transactional'), isTrue);
      expect(p.value('whatsapp', 'transactional'), isFalse);
      expect(p.value('push', 'promotional'), isFalse);
      expect(p.isLocked('in_app', 'transactional'), isTrue);
      expect(p.hasChannel('whatsapp'), isTrue);
      expect(NotificationPrefs.fromData(null), isNull);
    });

    testWidgets('opening the screen writes nothing and shows offers off', (
      tester,
    ) async {
      final adapter = _PrefsAdapter();
      await _pumpPrefs(tester, adapter);

      expect(adapter.puts, isEmpty, reason: 'consent is never saved unprompted');
      for (final key in [
        'pref_push_promotional',
        'pref_sms_promotional',
        'pref_email_promotional',
        'pref_in_app_promotional',
        'pref_whatsapp_transactional',
        'pref_whatsapp_promotional',
      ]) {
        expect(_switchOf(tester, key).value, isFalse, reason: key);
        expect(_switchOf(tester, key).onChanged, isNotNull, reason: key);
      }
      expect(find.textContaining('fraud'), findsNothing);
    });

    testWidgets('trip and account updates in the app and by push are fixed on', (
      tester,
    ) async {
      final adapter = _PrefsAdapter();
      await _pumpPrefs(tester, adapter);

      for (final key in ['pref_in_app_transactional', 'pref_push_transactional']) {
        final s = _switchOf(tester, key);
        expect(s.value, isTrue, reason: key);
        expect(s.onChanged, isNull, reason: '$key is disabled');
      }
      expect(
        find.text('Always on. Needed for your trips and your safety.'),
        findsNWidgets(2),
      );
      await tester.tap(
        find.byKey(const Key('pref_in_app_transactional')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(adapter.puts, isEmpty);
    });

    testWidgets('a toggle is saved as one explicit PUT and sticks', (
      tester,
    ) async {
      final adapter = _PrefsAdapter();
      await _pumpPrefs(tester, adapter);

      await tester.tap(find.byKey(const Key('pref_push_promotional')));
      await tester.pumpAndSettle();

      expect(adapter.puts, hasLength(1));
      expect(adapter.puts.single.path, endsWith('/notifications/preferences/'));
      expect(adapter.puts.single.data, {
        'preferences': [
          {'channel': 'push', 'category': 'promotional', 'opted_in': true},
        ],
      });
      expect(_switchOf(tester, 'pref_push_promotional').value, isTrue);
      expect(_switchOf(tester, 'pref_sms_promotional').value, isFalse);
      expect(find.byKey(const Key('prefs_error')), findsNothing);
    });

    testWidgets('WhatsApp has its own explicit opt-in toggle', (tester) async {
      final adapter = _PrefsAdapter();
      await _pumpPrefs(tester, adapter);
      expect(find.text('WhatsApp'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('pref_whatsapp_transactional')),
      );
      await tester.tap(find.byKey(const Key('pref_whatsapp_transactional')));
      await tester.pumpAndSettle();

      expect((adapter.puts.single.data as Map)['preferences'], [
        {'channel': 'whatsapp', 'category': 'transactional', 'opted_in': true},
      ]);
      expect(_switchOf(tester, 'pref_whatsapp_transactional').value, isTrue);
      expect(_switchOf(tester, 'pref_whatsapp_promotional').value, isFalse);
    });

    testWidgets('WhatsApp is shown only when the API lists it', (tester) async {
      final adapter = _PrefsAdapter(initial: prefsPayload(whatsapp: false));
      await _pumpPrefs(tester, adapter);

      expect(find.text('WhatsApp'), findsNothing);
      expect(find.byKey(const Key('pref_whatsapp_transactional')), findsNothing);
      expect(find.byKey(const Key('pref_whatsapp_promotional')), findsNothing);
      expect(find.byKey(const Key('pref_push_promotional')), findsOneWidget);
    });

    testWidgets('a failed save puts the switch back and says so', (tester) async {
      final adapter = _PrefsAdapter(putStatus: 500);
      await _pumpPrefs(tester, adapter);

      await tester.tap(find.byKey(const Key('pref_email_promotional')));
      await tester.pumpAndSettle();

      expect(adapter.puts, hasLength(1));
      expect(_switchOf(tester, 'pref_email_promotional').value, isFalse);
      expect(find.text(kPrefsSaveFailed), findsOneWidget);

      adapter.putStatus = 200;
      await tester.tap(find.byKey(const Key('pref_email_promotional')));
      await tester.pumpAndSettle();
      expect(_switchOf(tester, 'pref_email_promotional').value, isTrue);
      expect(find.byKey(const Key('prefs_error')), findsNothing);
    });
  });

  group('D8 earnings summary', () {
    test('the summary keys are read as the API sends them', () {
      final held = EarningsSummaryModel.fromJson(summaryHeld());
      expect(held.rewardsPendingReview, '300.00');
      expect(held.rewardsPendingReviewLabel, 'Pending review');
      final rec = EarningsSummaryModel.fromJson(summaryRecovered());
      expect(rec.rewardRecovery, '150.00');
      expect(rec.rewardRecoveryRemaining, '300.00');
      expect(rec.rewardRecoveryLabel, 'Recovery of reward (reviewed)');
      // A summary from before these keys existed.
      final old = EarningsSummaryModel.fromJson({
        'total_earned': '1000.00',
        'total_trips': 3,
      });
      expect(old.rewardsPendingReview, isNull);
      expect(old.rewardRecovery, isNull);
    });

    testWidgets('zero or absent: no new line appears', (tester) async {
      await tester.pumpWidget(_host(_card(summaryNothingNew())));
      expect(find.byKey(const Key('breakdown_rewards_pending_review')), findsNothing);
      expect(find.byKey(const Key('breakdown_reward_recovery')), findsNothing);
      expect(
        find.byKey(const Key('breakdown_reward_recovery_remaining')),
        findsNothing,
      );
      expect(find.textContaining('Pending review'), findsNothing);

      await tester.pumpWidget(
        _host(_card({'total_earned': '1000.00', 'total_trips': 3})),
      );
      expect(find.textContaining('Pending review'), findsNothing);
      expect(find.textContaining('Recovery'), findsNothing);
    });

    testWidgets('a held reward reads Pending review', (tester) async {
      await tester.pumpWidget(_host(_card(summaryHeld())));
      expect(find.byKey(const Key('breakdown_rewards_pending_review')), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('₹300.00'), findsOneWidget);
      expect(find.byKey(const Key('breakdown_reward_recovery')), findsNothing);
      expect(find.textContaining('raud'), findsNothing);
    });

    testWidgets('a recovery shows the line and what remains', (tester) async {
      await tester.pumpWidget(_host(_card(summaryRecovered())));
      expect(find.text('Recovery of reward (reviewed)'), findsOneWidget);
      expect(find.text('-₹150.00'), findsOneWidget);
      expect(find.text('Still to be recovered'), findsOneWidget);
      expect(find.text('₹300.00'), findsOneWidget);
      expect(find.byKey(const Key('breakdown_rewards_pending_review')), findsNothing);
      expect(find.textContaining('raud'), findsNothing);
    });
  });

  group('D8 incentive rows', () {
    PromoIncentive parse(Map<String, dynamic> row) =>
        PromoIncentive.listFromData({'incentives': [row]}).single;

    testWidgets('a held reward shows the API label and nothing about why', (
      tester,
    ) async {
      final i = parse(heldIncentiveRow());
      expect(i.stateAt(DateTime.now()), PromoIncentiveState.pendingReview);
      expect(i.labelAt(DateTime.now()), 'Pending review');
      await tester.pumpWidget(_host(PromoIncentiveCard(incentive: i)));
      expect(find.byKey(const Key('promo_incentive_state_11')), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.textContaining('raud'), findsNothing);
    });

    testWidgets('a row with no reward_status reads as it always did', (
      tester,
    ) async {
      final row = {
        ...heldIncentiveRow(),
        'status': 'in_progress',
        'progress_trips': 1,
        'reward_status': null,
        'reward_status_label': null,
      };
      final i = parse(row);
      await tester.pumpWidget(_host(PromoIncentiveCard(incentive: i)));
      expect(find.text('Pending review'), findsNothing);
      expect(find.text('In progress'), findsOneWidget);
    });
  });

  group('D8 payout on hold', () {
    test('PAYOUT_ON_HOLD becomes the neutral message, never the API wording', () async {
      final container = ProviderContainer(
        overrides: [
          earningsRepositoryProvider.overrideWithValue(
            _HoldRepo('PAYOUT_ON_HOLD', _heldMessageFromApi),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(earningsNotifierProvider.notifier);
      await notifier.loadInitialData();
      final ok = await notifier.requestWithdrawal(600.0);

      expect(ok, isFalse);
      final state = container.read(earningsNotifierProvider);
      expect(state.isSubmittingWithdrawal, isFalse);
      expect(state.errorMessage, kPayoutOnHoldMessage);
      expect(
        state.errorMessage,
        "Your payout is being checked. We'll let you know when it's released.",
      );
      expect(state.errorMessage!.toLowerCase(), isNot(contains('fraud')));
      expect(state.errorMessage, isNot(contains('contact support')));
      expect(state.withdrawalSuccessMessage, isNull);
    });

    test('another refusal still reads as a failed request', () async {
      final container = ProviderContainer(
        overrides: [
          earningsRepositoryProvider.overrideWithValue(
            _HoldRepo('SOMETHING_ELSE', 'nope'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(earningsNotifierProvider.notifier);
      await notifier.loadInitialData();
      await notifier.requestWithdrawal(600.0);
      expect(
        container.read(earningsNotifierProvider).errorMessage,
        startsWith('Withdrawal request failed'),
      );
    });

    testWidgets('the withdrawal sheet shows the neutral message', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.view.resetDevicePixelRatio();
      });
      final container = ProviderContainer(
        overrides: [
          earningsRepositoryProvider.overrideWithValue(
            _HoldRepo('PAYOUT_ON_HOLD', _heldMessageFromApi),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(earningsNotifierProvider.notifier).loadInitialData();
      await container
          .read(earningsNotifierProvider.notifier)
          .requestWithdrawal(600.0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: WithdrawalRequestBottomSheet()),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(kPayoutOnHoldMessage), findsOneWidget);
      expect(find.textContaining(_heldMessageFromApi), findsNothing);
    });
  });
}
