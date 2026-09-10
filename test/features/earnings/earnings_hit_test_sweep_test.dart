import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';
import 'package:saaradhigo_driver/domain/models/earning_model.dart';
import 'package:saaradhigo_driver/domain/models/earnings_summary_model.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_balance_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_model.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_notifier.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_state.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_notifier.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_providers.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/screens/earnings_dashboard_screen.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_notifier.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_providers.dart';
import 'package:saaradhigo_driver/core/theme/app_theme.dart';
import 'package:saaradhigo_driver/shared/widgets/app_bottom_nav.dart';

class FakeEarningsNotifier extends EarningsNotifier {
  FakeEarningsNotifier(this.seed);
  final EarningsState seed;
  @override
  EarningsState build() => seed;
  @override
  Future<void> loadInitialData() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> setPeriod(int i) async {
    state = state.copyWith(selectedPeriodIndex: i);
  }
}

class FakeProfileNotifier extends ProfileNotifier {
  FakeProfileNotifier(this.seed);
  final ProfileState seed;
  @override
  ProfileState build() => seed;
  @override
  Future<void> fetchProfile() async {}
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this.seed);
  final AuthState seed;
  @override
  AuthState build() => seed;
}

final _profile = DriverProfileModel(
  id: 1,
  user: const UserModel(id: 1, fullName: 'Ravi Kumar', avatar: null),
  status: DriverStatus.online,
  approved: true,
  ratings: 4.87,
);

EarningsState _seed({bool cash = true, bool empty = false}) => EarningsState(
  summary: const EarningsSummaryModel(
    totalEarned: '12450.75',
    totalCommission: '1245.07',
    totalTrips: 38,
    todayEarned: '1450.50',
    todayTrips: 6,
  ),
  earningsList: empty
      ? const []
      : const [
          EarningModel(id: 1, tripId: 101, netEarning: '520.00'),
          EarningModel(id: 2, tripId: 102, netEarning: '310.50'),
        ],
  withdrawalBalance: const WithdrawalBalanceModel(
    availableBalance: 8200.0,
    blocked: false,
    minimumWithdrawal: 500.0,
  ),
  withdrawalHistory: empty
      ? const []
      : const [WithdrawalModel(id: 1, amount: '2000.00', status: 'approved')],
  cashToCollect: cash ? 340.0 : null,
);

/// Mirrors `MainShellScreen`: extendBody + the glass bottom nav under the body,
/// under the real app theme (the button themes matter for layout) and behind a
/// GoRouter so `context.push('/profile')` taps resolve instead of throwing.
Widget _shellHarness(EarningsState seed) {
  final router = GoRouter(
    initialLocation: '/earnings',
    routes: [
      GoRoute(
        path: '/earnings',
        builder: (_, _) => Scaffold(
          extendBody: true,
          body: const EarningsDashboardScreen(),
          bottomNavigationBar: AppBottomNav(currentIndex: 2, onTap: (_) {}),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Center(child: Text('profile'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      earningsNotifierProvider.overrideWith(() => FakeEarningsNotifier(seed)),
      driverProfileNotifierProvider.overrideWith(
        () => FakeProfileNotifier(ProfileState.loaded(_profile)),
      ),
      authNotifierProvider.overrideWith(
        () => FakeAuthNotifier(const AuthAuthenticated()),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
  );
}

/// Layout errors that leave RenderBoxes unsized. `RenderFlex overflowed` is
/// deliberately excluded: the test font (1em-square glyphs) makes text far
/// wider than on a device, so overflow here is not a reliable signal.
const _fatalPatterns = <String>[
  'Cannot hit test a render box',
  'RenderBox was not laid out',
  'forces an infinite width',
  'forces an infinite height',
  'BoxConstraints has NaN',
  'has a negative min',
];

/// Installs an error collector for the duration of [body] and returns every
/// layout-invalidating error it saw.
Future<List<String>> _collectFatalErrors(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final fatal = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (_fatalPatterns.any(text.contains)) {
      fatal.add(text.split('\n').first);
    }
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return fatal;
}

/// Presses and releases at every [step] pixels across [size]. Any RenderBox in
/// a hit-test path that never received a size asserts here.
Future<void> _sweep(WidgetTester tester, Size size, {double step = 20}) async {
  for (double y = 4; y < size.height; y += step) {
    for (double x = 4; x < size.width; x += step) {
      final gesture = await tester.startGesture(Offset(x, y));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 1));
    }
  }
  await tester.pumpAndSettle();
}

void main() {
  const size = Size(360, 800);

  void setSurface(WidgetTester tester) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('grid hit test over the whole earnings surface', (tester) async {
    setSurface(tester);

    final fatal = await _collectFatalErrors(tester, () async {
      await tester.pumpWidget(_shellHarness(_seed()));
      await tester.pumpAndSettle();
      await _sweep(tester, size);
    });

    expect(fatal, isEmpty, reason: fatal.join('\n'));
  });

  testWidgets('withdrawal bottom sheet opens and hit tests', (tester) async {
    setSurface(tester);

    final fatal = await _collectFatalErrors(tester, () async {
      await tester.pumpWidget(_shellHarness(_seed()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('WITHDRAW'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), '100');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '600');
      await tester.pumpAndSettle();

      await _sweep(tester, size, step: 40);
    });

    expect(fatal, isEmpty, reason: fatal.join('\n'));
  });

  testWidgets('empty-state variant hit tests', (tester) async {
    setSurface(tester);

    final fatal = await _collectFatalErrors(tester, () async {
      await tester.pumpWidget(_shellHarness(_seed(cash: false, empty: true)));
      await tester.pumpAndSettle();

      // Pull-to-refresh, then sweep.
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      await _sweep(tester, size, step: 30);
    });

    expect(fatal, isEmpty, reason: fatal.join('\n'));
  });

  testWidgets('no unsized boxes across phone widths', (tester) async {
    for (final surface in const [
      Size(320, 640),
      Size(360, 800),
      Size(412, 915),
    ]) {
      tester.view.physicalSize = surface;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fatal = await _collectFatalErrors(tester, () async {
        await tester.pumpWidget(_shellHarness(_seed()));
        await tester.pumpAndSettle();
        await _sweep(tester, surface, step: 60);
      });

      expect(fatal, isEmpty, reason: '$surface\n${fatal.join('\n')}');
    }
  });
}
