/// Centralized route name constants for type-safe navigation.
/// All route strings are defined here to avoid magic strings throughout the app.
class RouteNames {
  // Auth flow
  static const String splash = '/splash';
  static const String login = '/login';
  static const String otp = '/otp';

  // Main app
  static const String dashboard = '/dashboard';
  static const String earnings = '/earnings';
  static const String tripHistory = '/trips';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  // Trip flow
  static const String incomingRideRequest = '/ride/incoming';
  static const String acceptedRide = '/ride/accepted';
  static const String activeTrip = '/ride/active';
  static const String arrivedAtPickup = '/ride/arrived';
  static const String tripDetails = '/ride/details';
  static const String tripSummary = '/ride/summary';

  // Settings & Support
  static const String helpSupport = '/support/help';
  static const String safetyCenter = '/safety';
  static const String emergencyContacts = '/safety/contacts';
  static const String reportIncident = '/safety/report';
  static const String supportTicketDetail = '/support/ticket';

  // Onboarding & Documents
  static const String documentVault = '/documents';
  static const String vehicleInfo = '/vehicle';
  static const String verificationStatus = '/verification';
  static const String onboardingPersonal = '/onboarding/personal';
  static const String onboardingLicense = '/onboarding/license';
  static const String onboardingPhotos = '/onboarding/photos';
  static const String onboardingVehicle = '/onboarding/vehicle';

  // Earnings sub-screens
  static const String incentivesRewards = '/earnings/incentives';
}
