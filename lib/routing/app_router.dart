import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_mobile_screen.dart';
import '../features/auth/presentation/otp_verification_screen.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/dashboard/presentation/driver_dashboard_screen.dart';
import '../features/earnings/presentation/screens/earnings_dashboard_screen.dart';
import '../features/dashboard/presentation/screens/messages_chat_screen.dart';
import '../features/dashboard/presentation/screens/trip_history_screen.dart';
import '../features/trip_history/presentation/screens/trip_details_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_licence_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_personal_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_photo_bank_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_vehicle_screen.dart';
import '../features/onboarding/presentation/screens/verification_status_screen.dart';
import '../features/documents/presentation/screens/document_vault_screen.dart';
import '../features/incentives/presentation/screens/elite_partner_screen.dart';
import '../features/incentives/presentation/screens/incentives_rewards_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/providers/profile_providers.dart';
import '../features/profile/presentation/screens/driver_profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/vehicle/presentation/screens/add_vehicle_screen.dart';
import '../features/vehicle/presentation/screens/vehicle_info_screen.dart';
import '../features/support/presentation/screens/emergency_contacts_screen.dart';
import '../features/support/presentation/screens/help_support_screen.dart';
import '../features/support/presentation/screens/report_incident_screen.dart';
import '../features/support/presentation/screens/safety_center_screen.dart';
import '../features/support/presentation/screens/support_ticket_detail_screen.dart';
import '../features/support/presentation/screens/trip_chat_screen.dart';
import '../features/trip/presentation/screens/trip_flow_screen.dart';
import '../shared/widgets/main_shell_screen.dart';
import 'page_not_found_screen.dart';

enum AppRoute { splash, login, otp, home, ride }

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // We read the auth state synchronously here.
      // We do NOT use ref.watch inside this provider because we don't want to recreate GoRouter.
      // Instead, we use a refreshListenable or ref.listen (see below).
      final authState = ref.read(authNotifierProvider);

      final isGoingToLogin = state.uri.path == '/login';
      final isGoingToSplash = state.uri.path == '/splash';
      final isGoingToOtp = state.uri.path == '/otp';
      final isGoingToVerificationStatus =
          state.uri.path == '/verification-status';
      final isOnboarding = state.uri.path.startsWith('/onboarding');

      if (authState is AuthUnknown) {
        return !isGoingToSplash ? '/splash' : null;
      } else if (authState is AuthUnauthenticated ||
          authState is AuthRequestingOtp) {
        return !isGoingToLogin ? '/login' : null;
      } else if (authState is AuthOtpSent) {
        return !isGoingToOtp
            ? Uri(
                path: '/otp',
                queryParameters: {'phone': authState.phoneNumber},
              ).toString()
            : null;
      } else if (authState is AuthVerifyingOtp) {
        return !isGoingToOtp
            ? Uri(
                path: '/otp',
                queryParameters: {'phone': authState.phoneNumber},
              ).toString()
            : null;
      } else if (authState is AuthAuthenticated) {
        final profileState = ref.read(driverProfileNotifierProvider);
        return profileState.maybeMap(
          initial: (_) {
            Future.microtask(
              () => ref
                  .read(driverProfileNotifierProvider.notifier)
                  .fetchProfile(),
            );
            return !isGoingToSplash ? '/splash' : null;
          },
          loading: (_) => null,
          error: (err) {
            debugPrint('Router Profile Error: ${err.message}');
            return null;
          },
          loaded: (s) {
            final profile = s.profile;

            // 1. If the driver is fully approved/verified by the backend, they belong on the home screen.
            if (profile.approved) {
              return (isGoingToLogin ||
                      isGoingToSplash ||
                      isGoingToOtp ||
                      isGoingToVerificationStatus ||
                      isOnboarding)
                  ? '/'
                  : null;
            }

            // 2. Since the backend omits the `user` object in /driver/profile, we infer `isUpdated`
            // by checking if they have uploaded a vehicle or license (which happen after personal details).
            final isUpdated =
                profile.user?.isUpdated ??
                (profile.activeVehicleDetails != null ||
                    profile.licenseDoc != null);

            if (!isUpdated) {
              // Driver has not completed personal details yet.
              return !isOnboarding ? '/onboarding/personal' : null;
            } else {
              // Driver has completed personal details but is NOT approved yet.
              // Allow them to navigate between other onboarding screens (vehicle, photo, licence).
              // If they are not on an onboarding screen, put them in the verification waiting room.
              if (isOnboarding) return null;
              return !isGoingToVerificationStatus
                  ? '/verification-status'
                  : null;
            }
          },
          orElse: () => null,
        );
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const LoginMobileScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: AppRoute.otp.name,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpVerificationScreen(phoneNumber: phone);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: AppRoute.home.name,
                builder: (context, state) => const DriverDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const TripHistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'trip/:id',
                    builder: (context, state) {
                      final tripId =
                          int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                      return TripDetailsScreen(tripId: tripId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/earnings',
                builder: (context, state) => const EarningsDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const MessagesChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const DriverProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding/personal',
        builder: (context, state) => const OnboardingPersonalScreen(),
      ),
      GoRoute(
        path: '/onboarding/photo-bank',
        builder: (context, state) => const OnboardingPhotoBankScreen(),
      ),
      GoRoute(
        path: '/onboarding/vehicle',
        builder: (context, state) => const OnboardingVehicleScreen(),
      ),
      GoRoute(
        path: '/onboarding/licence',
        builder: (context, state) => const OnboardingLicenceScreen(),
      ),
      GoRoute(
        path: '/verification-status',
        builder: (context, state) => const VerificationStatusScreen(),
      ),
      // Full-screen ride lifecycle, deliberately OUTSIDE the tab shell: an
      // active trip owns the whole screen. A single route renders the correct
      // state screen from TripSessionState (see TripFlowScreen).
      GoRoute(
        path: '/ride',
        name: AppRoute.ride.name,
        builder: (context, state) => const TripFlowScreen(),
      ),
      // Support, Safety & Comms — also OUTSIDE the tab shell so these flows
      // open over the shell (and over the active trip) as full screens.
      GoRoute(
        path: '/trip-chat/:tripId',
        builder: (context, state) {
          final tripId =
              int.tryParse(state.pathParameters['tripId'] ?? '') ?? 0;
          return TripChatScreen(
            tripId: tripId,
            riderName: state.uri.queryParameters['riderName'],
          );
        },
      ),
      GoRoute(
        path: '/safety',
        builder: (context, state) => const SafetyCenterScreen(),
      ),
      GoRoute(
        path: '/emergency-contacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/report-incident',
        builder: (context, state) => const ReportIncidentScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/support/ticket/:ticketId',
        builder: (context, state) {
          final ticketId =
              int.tryParse(state.pathParameters['ticketId'] ?? '') ?? 0;
          return SupportTicketDetailScreen(ticketId: ticketId);
        },
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentVaultScreen(),
      ),
      GoRoute(
        path: '/vehicle',
        builder: (context, state) => const VehicleInfoScreen(),
      ),
      GoRoute(
        path: '/vehicle/add',
        builder: (context, state) => const AddVehicleScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/incentives',
        builder: (context, state) => const IncentivesRewardsScreen(),
      ),
      GoRoute(
        path: '/elite',
        builder: (context, state) => const ElitePartnerScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        PageNotFoundScreen(errorMessage: state.error?.toString()),
  );

  // When auth state changes, tell the router to re-evaluate the redirect logic.
  ref.listen(authNotifierProvider, (previous, next) {
    router.refresh();
  });

  ref.listen(driverProfileNotifierProvider, (previous, next) {
    router.refresh();
  });

  return router;
});
