import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/earnings/presentation/earnings_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/safety/presentation/safety_screen.dart';
import '../features/safety/presentation/support_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/trip/presentation/active_trip_screen.dart';
import '../features/trip/presentation/trip_summary_screen.dart';
import '../features/withdrawals/presentation/withdrawals_screen.dart';

class Routes {
  const Routes._();
  static const splash = '/';
  static const login = '/login';
  static const otp = '/login/otp';
  static const home = '/home';
  static const activeTrip = '/trip';
  static const tripSummary = '/trip/summary';
  static const earnings = '/earnings';
  static const withdrawals = '/withdrawals';
  static const history = '/history';
  static const profile = '/profile';
  static const safety = '/safety';
  static const support = '/support';
  static const settings = '/settings';
}

/// Bridges a Riverpod provider to GoRouter's `refreshListenable`.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // Splash owns the restore handshake; never redirect away from it.
      if (loc == Routes.splash) return null;

      final isAuthRoute = loc == Routes.login || loc == Routes.otp;

      switch (auth.status) {
        case AuthStatus.unknown:
          return Routes.splash;
        case AuthStatus.signedOut:
          return isAuthRoute ? null : Routes.login;
        case AuthStatus.signedIn:
          return isAuthRoute ? Routes.home : null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (_, _) => const OtpScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.activeTrip,
        builder: (_, _) => const ActiveTripScreen(),
        routes: [
          GoRoute(
            path: 'summary',
            builder: (_, _) => const TripSummaryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.earnings,
        builder: (_, _) => const EarningsScreen(),
      ),
      GoRoute(
        path: Routes.withdrawals,
        builder: (_, _) => const WithdrawalsScreen(),
      ),
      GoRoute(
        path: Routes.history,
        builder: (_, _) => const HistoryScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.safety,
        builder: (_, _) => const SafetyScreen(),
      ),
      GoRoute(
        path: Routes.support,
        builder: (_, _) => const SupportScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No screen at ${state.uri}')),
    ),
  );
});
