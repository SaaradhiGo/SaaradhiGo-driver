import 'environment_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => EnvironmentConfig.apiBaseUrl;
  static String get wsBaseUrl => EnvironmentConfig.wsBaseUrl;

  // Authentication
  static const String requestOtp = '/auth/otp/';
  static const String login = '/auth/login/';
  static const String refreshToken = '/auth/refresh/';
  static const String updateProfile = '/auth/update/';
  static const String updateBankDetails = '/auth/bank-details/';
  static const String getProfile = '/auth/profile/';
  static const String logout = '/auth/logout/';

  // Email + password, alongside phone + OTP. Paths taken from the
  // generated contract (test/contracts/auth_contracts.json), not guessed.
  static const String emailLogin = '/auth/email/login/';
  static const String passwordForgot = '/auth/password/forgot/';

  // Driver Profile & Vehicles
  static const String driverProfile = '/driver/driver/profile/';
  static const String driverUpdate = '/driver/driver/update/';
  static const String driverVehicles = '/driver/vehicles/';
  static const String addVehicle = '/driver/vehicles/add/';
  static String updateVehicle(String vehicleId) =>
      '/driver/vehicles/$vehicleId/';

  // Uploads (presigned direct-to-S3)
  static const String presignUpload = '/uploads/presign/';

  // Driver Earnings, Incentives & Elite Status
  static const String driverEarnings = '/driver/earnings/';
  static const String driverEarningsSummary = '/driver/earnings/summary/';
  // The doubled `driver/` is correct and is not a typo: servers/driver/urls.py
  // is included at `/driver/` and declares `path('driver/incentives/')`, so
  // the full route is /api/v1/driver/driver/incentives/.
  //
  // These were a pair each -- a single-segment "primary" and a doubled
  // "fallback" tried on 404. The primary never existed, so every incentives
  // and elite-status read made one guaranteed-404 request before the real
  // one. Collapsed to the route the server actually serves.
  static const String driverIncentives = '/driver/driver/incentives/';
  static const String driverEliteStatus = '/driver/driver/elite-status/';

  // Wallet & Withdrawals
  static const String walletBalance = '/rider/wallet/balance/';
  static const String driverWithdrawalBalance = '/driver/withdrawals/balance/';
  static const String driverWithdrawalRequest = '/driver/withdrawals/request/';
  static const String driverWithdrawalHistory = '/driver/withdrawals/history/';
  static const String driverWithdrawalBlockStatus =
      '/driver/withdrawals/block-status/';

  // Ride Execution
  static const String activeTrip = '/ride/active/';
  static const String tripHistory = '/ride/driver-history/';
  static String tripDetails(String tripId) => '/ride/trip/$tripId/';
  static String driverCancelTrip(String tripId) =>
      '/ride/trip/$tripId/driver-cancel/';

  // Ride Chat & Support, Safety
  static String tripChatHistory(String tripId) => '/ride/trip/$tripId/chat/';
  static const String sosRaise = '/sos/';
  static const String supportTickets = '/support/tickets/';
  static const String supportCreateTicket = '/support/tickets/create/';
  static String supportTicketDetail(String ticketId) =>
      '/support/tickets/$ticketId/';
  static String supportTicketMessages(String ticketId) =>
      '/support/tickets/$ticketId/messages/';
  static String supportTicketClose(String ticketId) =>
      '/support/tickets/$ticketId/close/';

  // Notifications
  static const String notifications = '/rider/notifications/';
  static String notificationRead(int id) => '/rider/notifications/$id/read/';
  static const String notificationsReadAll = '/rider/notifications/read-all/';

  // WebSockets (Relative to wsBaseUrl)
  static const String wsDriverLocation = 'ws/driver/location/';
  static String wsTripStatus(String tripId) => 'ws/ride/trip/$tripId/';
  static String wsTripChat(String tripId) => 'ws/ride/trip/$tripId/chat/';
}
