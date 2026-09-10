import 'package:flutter/material.dart';
import 'route_names.dart';
import '../screens/auth/login_mobile_number.dart';
import '../screens/auth/otp_verification.dart';

import '../screens/main_navigation_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/trips/incoming_ride_request_screen.dart';
import '../screens/trips/accepted_ride_screen.dart';
import '../screens/trips/active_trip_navigation_screen.dart';
import '../screens/trips/arrived_at_pickup_screen.dart';
import '../screens/trips/trip_details_screen.dart';
import '../screens/trips/trip_summary_screen.dart';
import '../screens/support/help_support_screen.dart';
import '../screens/safety/safety_center_screen.dart';
import '../screens/safety/emergency_contacts_screen.dart';
import '../screens/safety/report_incident_screen.dart';
import '../screens/support/support_ticket_detail_screen.dart';
import '../screens/documents/document_vault_screen.dart';
import '../screens/vehicle/vehicle_info_screen.dart';
import '../screens/onboarding/verification_status_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/onboarding/onboarding_license_screen.dart';
import '../screens/onboarding/onboarding_photo_screen.dart';
import '../screens/onboarding/onboarding_vehicle_screen.dart';
import '../screens/earnings/incentives_rewards_screen.dart';

/// Centralized route generation for the SaaradhiGo Driver App.
/// Handles all named route resolution with premium slide transitions.
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth flow

      case RouteNames.login:
        return _buildRoute(const LoginMobileNumberScreen(), settings);

      case RouteNames.otp:
        final phoneNumber = settings.arguments as String? ?? '';
        return _buildRoute(
          OtpVerificationScreen(phoneNumber: phoneNumber),
          settings,
        );

      // Main App Tabs
      case RouteNames.dashboard:
        return _buildRoute(const MainNavigationScreen(), settings);

      case RouteNames.earnings:
        return _buildRoute(
          const MainNavigationScreen(initialIndex: 2),
          settings,
        );

      case RouteNames.tripHistory:
        return _buildRoute(
          const MainNavigationScreen(initialIndex: 1),
          settings,
        );

      case RouteNames.messages:
        return _buildRoute(
          const MainNavigationScreen(initialIndex: 3),
          settings,
        );

      case RouteNames.profile:
        return _buildRoute(
          const MainNavigationScreen(initialIndex: 4),
          settings,
        );

      case RouteNames.notifications:
        return _buildRoute(const NotificationsScreen(), settings);

      // Trip Flow
      case RouteNames.incomingRideRequest:
        return _buildRoute(const IncomingRideRequestScreen(), settings);

      case RouteNames.acceptedRide:
        return _buildRoute(const AcceptedRideScreen(), settings);

      case RouteNames.arrivedAtPickup:
        return _buildRoute(const ArrivedAtPickupScreen(), settings);

      case RouteNames.activeTrip:
        return _buildRoute(const ActiveTripNavigationScreen(), settings);

      case RouteNames.tripDetails:
        return _buildRoute(const TripDetailsScreen(), settings);

      case RouteNames.tripSummary:
        return _buildRoute(const TripSummaryScreen(), settings);

      // Settings & Support
      case RouteNames.helpSupport:
        return _buildRoute(const HelpSupportScreen(), settings);

      case RouteNames.safetyCenter:
        return _buildRoute(const SafetyCenterScreen(), settings);

      case RouteNames.emergencyContacts:
        return _buildRoute(const EmergencyContactsScreen(), settings);

      case RouteNames.reportIncident:
        return _buildRoute(const ReportIncidentScreen(), settings);

      case RouteNames.supportTicketDetail:
        return _buildRoute(const SupportTicketDetailScreen(), settings);

      // Onboarding & Documents
      case RouteNames.documentVault:
        return _buildRoute(const DocumentVaultScreen(), settings);

      case RouteNames.vehicleInfo:
        return _buildRoute(const VehicleInfoScreen(), settings);

      case RouteNames.verificationStatus:
        return _buildRoute(const VerificationStatusScreen(), settings);

      case RouteNames.onboardingPersonal:
        return _buildRoute(const ProfileSetupScreen(), settings);

      case RouteNames.onboardingLicense:
        return _buildRoute(const OnboardingLicenseScreen(), settings);

      case RouteNames.onboardingPhotos:
        return _buildRoute(const OnboardingPhotoScreen(), settings);

      case RouteNames.onboardingVehicle:
        return _buildRoute(const OnboardingVehicleScreen(), settings);

      case RouteNames.incentivesRewards:
        return _buildRoute(const IncentivesRewardsScreen(), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text(
                'Route not found: ${settings.name}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          settings,
        );
    }
  }

  /// Build a route with a smooth slide-up transition
  /// matching the premium app aesthetic.
  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
