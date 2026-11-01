/// App catch-up phase 3 (growth), driver: D3 incentives and referrals.
///
/// Payloads are the shapes servers/promotions/incentives.py::driver_view and
/// referrals.py::mine return (see tests/test_promotions_incentives.py and
/// tests/test_promotions_referrals.py in the backend: a quest of 3 trips with a
/// 30_000 minor INR reward, progress 1 of 3, status in_progress, commission
/// 'none', tax 'not configured').
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saaradhigo_driver/core/market/market_config.dart';
import 'package:saaradhigo_driver/core/market/market_config_store.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/core/theme/app_theme.dart';
import 'package:saaradhigo_driver/domain/models/elite_status_model.dart';
import 'package:saaradhigo_driver/domain/models/incentive_quest_model.dart';
import 'package:saaradhigo_driver/domain/models/promo_incentive_model.dart';
import 'package:saaradhigo_driver/domain/models/referral_models.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';
import 'package:saaradhigo_driver/domain/models/earnings_summary_model.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_notifier.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_state.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_notifier.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_providers.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/screens/earnings_dashboard_screen.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_notifier.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_providers.dart';
import 'package:saaradhigo_driver/features/profile/presentation/screens/driver_profile_screen.dart';
import 'package:saaradhigo_driver/features/vehicle/presentation/providers/vehicle_info_providers.dart';
import 'package:saaradhigo_driver/features/incentives/domain/repositories/incentives_repository.dart';
import 'package:saaradhigo_driver/features/incentives/presentation/providers/incentives_providers.dart';
import 'package:saaradhigo_driver/features/incentives/presentation/providers/promo_incentives_provider.dart';
import 'package:saaradhigo_driver/features/incentives/presentation/screens/incentives_rewards_screen.dart';
import 'package:saaradhigo_driver/features/referrals/presentation/providers/referral_provider.dart';
import 'package:saaradhigo_driver/features/referrals/presentation/screens/referral_screen.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> incentiveRow({
  int id = 11,
  String name = 'Weekend 3',
  String state = 'live',
  int target = 3,
  int progress = 1,
  String status = 'in_progress',
  int rewardMinor = 30000,
  String currency = 'INR',
  String? endsAt,
  bool budgetUsedUp = false,
  String? rewardStatus,
}) => {
  'id': id,
  'name': name,
  'description': 'Weekend supply push',
  'state': state,
  'target_trips': target,
  'progress_trips': progress,
  'status': status,
  'reward_minor': rewardMinor,
  'currency': currency,
  'reward': currency == 'USD' ? r'$300.00' : '₹300.00',
  'starts_at': '2026-11-01T00:00:00+00:00',
  'ends_at':
      endsAt ??
      DateTime.now().add(const Duration(days: 5)).toUtc().toIso8601String(),
  'filters': <String, dynamic>{},
  'budget_used_up': budgetUsedUp,
  'reward_status': rewardStatus,
  'reward_status_label': rewardStatus == null ? null : 'Pending review',
  'commission': 'none',
  'tax': 'not configured',
};

Map<String, dynamic> incentivesEnvelope(List<Map<String, dynamic>> rows) => {
  'status': 'success',
  'data': {'incentives': rows, 'tax': 'not configured'},
};

Map<String, dynamic> mineLive() => {
  'code': 'WXYZ2345',
  'offer': {
    'campaign_id': 9,
    'name': 'Refer a driver',
    'required_trips': 5,
    'referrer_reward_minor': 10000,
    'referee_reward_minor': 5000,
    'currency': 'INR',
    'referrer_reward': '₹100.00',
    'referee_reward': '₹50.00',
  },
  'referrals': [
    {
      'id': 1,
      'who': 'Kiran M.',
      'status': 'rewarded',
      'trips_completed': 5,
      'required_trips': 5,
      'reward_minor': 10000,
      'currency': 'INR',
      'note': '',
      'reward_status': null,
      'joined_at': '2026-11-01T09:00:00+00:00',
    },
    {
      'id': 2,
      'who': 'Suresh',
      'status': 'attached',
      'trips_completed': 2,
      'required_trips': 5,
      'reward_minor': 0,
      'currency': 'INR',
      'note': '',
      'reward_status': null,
      'joined_at': '2026-11-01T09:30:00+00:00',
    },
    {
      'id': 3,
      'who': 'Anil K.',
      'status': 'blocked',
      'trips_completed': 5,
      'required_trips': 5,
      'reward_minor': 0,
      'currency': 'INR',
      'note': 'under review',
      'reward_status': null,
      'joined_at': '2026-11-01T10:00:00+00:00',
    },
  ],
  'attached_to': null,
};

Map<String, dynamic> mineNoOffer() => {
  'code': 'WXYZ2345',
  'offer': null,
  'referrals': <dynamic>[],
  'attached_to': null,
};

MarketConfig market({bool? referrals}) => MarketConfig.fromData({
  'country': {
    'code': 'IN',
    'name': 'India',
    'calling_code': '91',
    'currency': {'code': 'INR', 'symbol': '₹', 'minor_units': 2},
    'distance_unit': 'km',
  },
  'cities': <dynamic>[],
  'notices': <dynamic>[],
  'referrals_available': ?referrals,
});

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Dio _dio(_StubAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://qa.example.test/api/v1/'))
      ..httpClientAdapter = adapter;

class _FakePromoService implements PromoIncentivesService {
  _FakePromoService(this.rows, {this.fail = false});
  final List<PromoIncentive> rows;
  final bool fail;

  @override
  Dio get dio => throw UnimplementedError();

  @override
  Future<List<PromoIncentive>> fetch() async {
    if (fail) throw Exception('offline');
    return rows;
  }
}

class _LegacyRepo implements IncentivesRepository {
  _LegacyRepo(this.quests);
  final List<IncentiveQuestModel> quests;

  @override
  Future<List<IncentiveQuestModel>> getIncentives() async => quests;

  @override
  Future<EliteStatusModel> getEliteStatus() async =>
      const EliteStatusModel(tier: 'Gold');
}

List<PromoIncentive> _parse(List<Map<String, dynamic>> rows) =>
    PromoIncentive.listFromData(incentivesEnvelope(rows)['data']);

class _FakeEarnings extends EarningsNotifier {
  @override
  EarningsState build() => const EarningsState(
    summary: EarningsSummaryModel(
      totalEarned: '12450.75',
      totalCommission: '1245.07',
      totalTrips: 38,
      todayEarned: '1450.50',
      todayTrips: 6,
    ),
  );
  @override
  Future<void> loadInitialData() async {}
  @override
  Future<void> refresh() async {}
}

class _FakeProfile extends ProfileNotifier {
  @override
  ProfileState build() => const ProfileState.loaded(
    DriverProfileModel(
      id: 1,
      user: UserModel(id: 1, fullName: 'Ravi Kumar'),
      approved: true,
      ratings: 4.8,
    ),
  );
  @override
  Future<void> fetchProfile() async {}
}

class _FakeAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthAuthenticated();
}

class _FakeVehicle extends VehicleInfoNotifier {
  @override
  VehicleInfoState build() =>
      const VehicleInfoState(status: VehicleInfoStatus.empty);
  @override
  Future<void> fetchVehicleInfo({bool refresh = false}) async {}
}

List<Override> _screenOverrides(PromoIncentivesService promo) => [
  earningsNotifierProvider.overrideWith(_FakeEarnings.new),
  driverProfileNotifierProvider.overrideWith(_FakeProfile.new),
  authNotifierProvider.overrideWith(_FakeAuth.new),
  vehicleInfoNotifierProvider.overrideWith(_FakeVehicle.new),
  promoIncentivesServiceProvider.overrideWithValue(promo),
];

// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('D3 incentive model', () {
    test('parses the backend row and shows progress, reward and note', () {
      final i = _parse([incentiveRow()]).single;
      expect(i.name, 'Weekend 3');
      expect(i.progressText, '1 of 3 trips');
      expect(i.rewardMinor, 30000);
      expect(i.rewardText, '₹300.00');
      expect(i.stateAt(now), PromoIncentiveState.inProgress);
      expect(
        i.rewardNote,
        'No commission · Tax: not configured · Paid in your weekly payout',
      );
    });

    test('a US incentive shows its own currency, not the rupee', () {
      final i = _parse([
        incentiveRow(currency: 'USD', rewardMinor: 5000),
      ]).single;
      expect(i.rewardText, r'$50.00');
    });

    test('a row with no currency falls back to the market currency', () {
      MarketConfigStore.instance.debugSet(market());
      final i = _parse([incentiveRow(currency: '')]).single;
      expect(i.rewardText, '₹300.00');
    });

    test('each state', () {
      PromoIncentiveState of(Map<String, dynamic> row) =>
          _parse([row]).single.stateAt(now);
      expect(
        of(incentiveRow(progress: 12, target: 20)),
        PromoIncentiveState.inProgress,
      );
      expect(
        of(incentiveRow(progress: 3, status: 'completed')),
        PromoIncentiveState.earned,
      );
      expect(
        of(
          incentiveRow(
            progress: 3,
            status: 'completed',
            rewardStatus: 'pending_review',
          ),
        ),
        PromoIncentiveState.pendingReview,
      );
      expect(
        of(incentiveRow(progress: 3, status: 'unfunded', budgetUsedUp: true)),
        PromoIncentiveState.budgetUsedUp,
      );
      expect(
        of(incentiveRow(state: 'exhausted', budgetUsedUp: true)),
        PromoIncentiveState.budgetUsedUp,
      );
      expect(of(incentiveRow(state: 'paused')), PromoIncentiveState.paused);
      expect(
        of(
          incentiveRow(
            endsAt: now
                .subtract(const Duration(hours: 1))
                .toUtc()
                .toIso8601String(),
          ),
        ),
        PromoIncentiveState.expired,
      );
    });

    test('an empty or malformed body is an empty list, not a throw', () {
      expect(PromoIncentive.listFromData(null), isEmpty);
      expect(PromoIncentive.listFromData({'incentives': 'x'}), isEmpty);
      expect(PromoIncentive.listFromData({'incentives': <dynamic>[]}), isEmpty);
    });
  });

  group('D3 service', () {
    test(
      'reads /promotions/driver/incentives/ and parses the envelope',
      () async {
        final adapter = _StubAdapter(
          (o) async => _json(
            incentivesEnvelope([
              incentiveRow(),
              incentiveRow(id: 12, name: 'Night 5'),
            ]),
          ),
        );
        final rows = await PromoIncentivesService(_dio(adapter)).fetch();
        expect(
          adapter.requests.single.path,
          ApiEndpoints.promotionsDriverIncentives,
        );
        expect(
          ApiEndpoints.promotionsDriverIncentives,
          '/promotions/driver/incentives/',
        );
        expect(rows.map((r) => r.name), ['Weekend 3', 'Night 5']);
      },
    );
  });

  group('D3 earnings card summary', () {
    PromoIncentivesState loaded(List<Map<String, dynamic>> rows) =>
        PromoIncentivesState(
          status: PromoIncentivesStatus.loaded,
          items: _parse(rows),
        );

    test(
      'keeps the standing wording until something has loaded or when it failed',
      () {
        expect(
          incentivesCardSummary(const PromoIncentivesState(), now),
          isNull,
        );
        expect(
          incentivesCardSummary(
            const PromoIncentivesState(status: PromoIncentivesStatus.error),
            now,
          ),
          isNull,
        );
      },
    );

    test('nothing active reads "No active incentives right now"', () {
      expect(
        incentivesCardSummary(loaded([]), now),
        'No active incentives right now',
      );
      expect(
        incentivesCardSummary(
          loaded([incentiveRow(status: 'completed', progress: 3)]),
          now,
        ),
        'No active incentives right now',
      );
    });

    test('shows the first active incentive and how many more', () {
      expect(
        incentivesCardSummary(loaded([incentiveRow()]), now),
        'Weekend 3: 1 of 3 trips',
      );
      expect(
        incentivesCardSummary(
          loaded([incentiveRow(), incentiveRow(id: 12, name: 'Night 5')]),
          now,
        ),
        'Weekend 3: 1 of 3 trips · +1 more',
      );
    });
  });

  group('D3 incentives screen', () {
    Future<void> pump(
      WidgetTester t, {
      required List<Map<String, dynamic>> promo,
      List<IncentiveQuestModel> legacy = const [],
      bool promoFails = false,
    }) async {
      t.view.physicalSize = const Size(412, 1400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      final router = GoRouter(
        initialLocation: '/incentives',
        routes: [
          GoRoute(
            path: '/incentives',
            builder: (_, _) => const IncentivesRewardsScreen(),
          ),
          GoRoute(path: '/elite', builder: (_, _) => const Scaffold()),
          GoRoute(path: '/earnings', builder: (_, _) => const Scaffold()),
        ],
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            incentivesRepositoryProvider.overrideWithValue(_LegacyRepo(legacy)),
            promoIncentivesServiceProvider.overrideWithValue(
              _FakePromoService(_parse(promo), fail: promoFails),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await t.pump();
      await t.pump();
      await t.pump();
    }

    testWidgets(
      'an in-progress and an earned quest, exactly as the API returns them',
      (t) async {
        await pump(
          t,
          promo: [
            incentiveRow(id: 11, name: 'Weekend 20', target: 20, progress: 12),
            incentiveRow(
              id: 12,
              name: 'Night 5',
              target: 5,
              progress: 5,
              status: 'completed',
              rewardMinor: 50000,
            ),
          ],
        );
        expect(
          find.byKey(const Key('promo_incentives_section')),
          findsOneWidget,
        );
        expect(find.text('Weekend 20'), findsOneWidget);
        expect(find.text('12 of 20 trips'), findsOneWidget);
        expect(find.text('Reward ₹300.00'), findsOneWidget);
        expect(find.text('In progress'), findsOneWidget);
        expect(find.text('Night 5'), findsOneWidget);
        expect(find.text('5 of 5 trips'), findsOneWidget);
        expect(find.text('Reward ₹500.00'), findsOneWidget);
        expect(find.text('Earned'), findsOneWidget);
        expect(
          find.text(
            'No commission · Tax: not configured · Paid in your weekly payout',
          ),
          findsNWidgets(2),
        );
        // The old placeholder rings (12/20 and 15/50 made up by the app) are gone.
        expect(find.text('Daily Goal'), findsNothing);
        expect(find.text('Weekly Milestone'), findsNothing);
      },
    );

    testWidgets('a held reward reads Pending review, never why', (t) async {
      await pump(
        t,
        promo: [
          incentiveRow(
            status: 'completed',
            progress: 3,
            rewardStatus: 'pending_review',
          ),
        ],
      );
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.textContaining('fraud'), findsNothing);
    });

    testWidgets('expired, paused and used-up budget each say so', (t) async {
      await pump(
        t,
        promo: [
          incentiveRow(id: 1, name: 'A', state: 'paused'),
          incentiveRow(
            id: 2,
            name: 'B',
            state: 'exhausted',
            budgetUsedUp: true,
          ),
          incentiveRow(
            id: 3,
            name: 'C',
            endsAt: DateTime.now()
                .subtract(const Duration(hours: 2))
                .toUtc()
                .toIso8601String(),
          ),
        ],
      );
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('Offer budget used up'), findsOneWidget);
      expect(find.text('Ended'), findsOneWidget);
    });

    testWidgets('nothing from either source keeps today\'s empty state', (
      t,
    ) async {
      await pump(t, promo: []);
      expect(find.text('No Active Quests'), findsOneWidget);
      expect(find.byKey(const Key('promo_incentives_section')), findsNothing);
    });

    testWidgets('legacy quests alone look as they did before', (t) async {
      await pump(
        t,
        promo: [],
        legacy: const [
          IncentiveQuestModel(
            id: 1,
            title: 'Daily Goal',
            targetTrips: 20,
            progressTrips: 12,
            rewardAmount: '300.00',
            type: 'daily_goal',
          ),
        ],
      );
      expect(find.text('Active Targets'), findsOneWidget);
      expect(find.byKey(const Key('promo_incentives_section')), findsNothing);
    });

    testWidgets('a failed promo request leaves the legacy screen alone', (
      t,
    ) async {
      await pump(
        t,
        promo: [],
        promoFails: true,
        legacy: const [
          IncentiveQuestModel(
            id: 1,
            title: 'Daily Goal',
            targetTrips: 20,
            progressTrips: 12,
            rewardAmount: '300.00',
            type: 'daily_goal',
          ),
        ],
      );
      expect(find.text('Active Targets'), findsOneWidget);
    });
  });

  group('D3 referral flag', () {
    test('referrals_available is read from app-config; missing is false', () {
      expect(market().referralsAvailable, isFalse);
      expect(market(referrals: false).referralsAvailable, isFalse);
      expect(market(referrals: true).referralsAvailable, isTrue);
      expect(MarketConfig.builtIn.referralsAvailable, isFalse);
    });

    test('the driver asks app-config with app=driver', () async {
      Uri? seen;
      final store = MarketConfigStore(
        dio: _dio(
          _StubAdapter((o) async {
            seen = o.uri;
            return _json({
              'status': 'success',
              'data': {
                'country': {
                  'code': 'IN',
                  'name': 'India',
                  'calling_code': '91',
                  'currency': {'code': 'INR', 'symbol': '₹', 'minor_units': 2},
                  'distance_unit': 'km',
                },
                'referrals_available': true,
              },
            });
          }),
        ),
      );
      await store.refresh(country: 'IN');
      expect(seen!.queryParameters['app'], 'driver');
      expect(store.current.referralsAvailable, isTrue);
    });
  });

  group('D3 referral screen', () {
    Future<List<String>> pump(
      WidgetTester t,
      Object? body, {
      int status = 200,
    }) async {
      t.view.physicalSize = const Size(412, 1400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      final shared = <String>[];
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            referralServiceProvider.overrideWithValue(
              ReferralService(
                _dio(
                  _StubAdapter((o) async => _json(body ?? {}, status: status)),
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: DriverReferralScreen(
              shareOverride: (s) async => shared.add(s),
            ),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      return shared;
    }

    testWidgets('code, offer in driver wording, progress and pending review', (
      t,
    ) async {
      await pump(t, {'status': 'success', 'data': mineLive()});
      expect(find.text('WXYZ2345'), findsOneWidget);
      expect(
        find.text(
          'When a driver you refer completes 5 trips, you get ₹100.00 and they get ₹50.00.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'No commission · Tax: not configured · Paid in your weekly payout',
        ),
        findsOneWidget,
      );
      expect(find.text('Rewards earned: ₹100.00'), findsOneWidget);
      expect(find.text('2 of 5 trips'), findsOneWidget);
      expect(find.text('Pending review'), findsNWidgets(2)); // stat label + row
      expect(find.textContaining('fraud'), findsNothing);
      expect(find.textContaining('same_'), findsNothing);
    });

    testWidgets('no offer: neutral line, no zero headline', (t) async {
      await pump(t, {'status': 'success', 'data': mineNoOffer()});
      expect(find.byKey(const Key('referral_no_offer')), findsOneWidget);
      expect(find.byKey(const Key('referral_empty')), findsOneWidget);
      expect(find.text('No rewards earned yet'), findsOneWidget);
      expect(find.textContaining('₹0'), findsNothing);
    });

    testWidgets('share sends a neutral line with the code', (t) async {
      final shared = await pump(t, {'status': 'success', 'data': mineLive()});
      await t.tap(find.text('Share'));
      await t.pump();
      expect(shared.single, contains('WXYZ2345'));
      expect(shared.single, startsWith('Drive with SaaradhiGo.'));
    });

    testWidgets('a failed load offers a retry', (t) async {
      await pump(t, {'status': 'error'}, status: 500);
      expect(find.text('Try again'), findsOneWidget);
    });

    test('the model sums earned and pending per currency', () {
      final mine = ReferralMine.fromData(mineLive())!;
      expect(mine.invites, 3);
      expect(mine.pendingReviewCount, 1);
      expect(mine.earnedMinorByCurrency, {'INR': 10000});
    });
  });

  group('D3 earnings card', () {
    Future<void> pumpEarnings(
      WidgetTester t,
      PromoIncentivesService promo,
    ) async {
      t.view.physicalSize = const Size(1100, 1600);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      final router = GoRouter(
        initialLocation: '/earnings',
        routes: [
          GoRoute(
            path: '/earnings',
            builder: (_, _) => const EarningsDashboardScreen(),
          ),
          GoRoute(
            path: '/incentives',
            builder: (_, _) => const Scaffold(body: Text('INCENTIVES SCREEN')),
          ),
          GoRoute(path: '/profile', builder: (_, _) => const Scaffold()),
        ],
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: _screenOverrides(promo),
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await t.pump();
      await t.pump();
      await t.pump();
    }

    String summary(WidgetTester t) =>
        t.widget<Text>(find.byKey(const Key('incentives_card_summary'))).data!;

    testWidgets('shows the active quest and opens the incentives screen', (
      t,
    ) async {
      await pumpEarnings(
        t,
        _FakePromoService(_parse([incentiveRow(target: 20, progress: 12)])),
      );
      expect(find.text('Incentives & Quests'), findsOneWidget);
      expect(summary(t), 'Weekend 3: 12 of 20 trips');
      await t.ensureVisible(find.text('Incentives & Quests'));
      await t.tap(find.text('Incentives & Quests'));
      await t.pumpAndSettle();
      expect(find.text('INCENTIVES SCREEN'), findsOneWidget);
    });

    testWidgets('no incentives: the empty state, and the card stays', (
      t,
    ) async {
      await pumpEarnings(t, _FakePromoService(const []));
      expect(find.text('Incentives & Quests'), findsOneWidget);
      expect(summary(t), 'No active incentives right now');
    });

    testWidgets('a failed request keeps the card exactly as it was', (t) async {
      await pumpEarnings(t, _FakePromoService(const [], fail: true));
      expect(
        summary(t),
        'Complete ride milestones & unlock weekly cash bonuses',
      );
    });
  });

  group('D3 profile menu entry', () {
    Future<void> pumpProfile(WidgetTester t, MarketConfig m) async {
      MarketConfigStore.instance.debugSet(m);
      addTearDown(
        () => MarketConfigStore.instance.debugSet(MarketConfig.builtIn),
      );
      t.view.physicalSize = const Size(1100, 2000);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (_, _) => const DriverProfileScreen(),
          ),
          GoRoute(
            path: '/refer',
            builder: (_, _) => const Scaffold(body: Text('REFER SCREEN')),
          ),
        ],
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: _screenOverrides(_FakePromoService(const [])),
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('hidden when the flag is false or missing', (t) async {
      for (final m in [market(), market(referrals: false)]) {
        await pumpProfile(t, m);
        expect(find.text('Elite Tier'), findsOneWidget);
        expect(find.byKey(const Key('profile_refer_tile')), findsNothing);
        expect(find.text('Refer & Earn'), findsNothing);
      }
    });

    testWidgets(
      'shown and opens the referral screen when a driver offer is live',
      (t) async {
        await pumpProfile(t, market(referrals: true));
        expect(find.byKey(const Key('profile_refer_tile')), findsOneWidget);
        await t.ensureVisible(find.byKey(const Key('profile_refer_tile')));
        await t.tap(find.byKey(const Key('profile_refer_tile')));
        await t.pumpAndSettle();
        expect(find.text('REFER SCREEN'), findsOneWidget);
      },
    );
  });
}
