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

  // WebSockets (Relative to wsBaseUrl)
  static const String wsDriverLocation = 'ws/driver/location/';
  static String wsTripStatus(String tripId) => 'ws/ride/trip/$tripId/';
  static String wsTripChat(String tripId) => 'ws/ride/trip/$tripId/chat/';
}
