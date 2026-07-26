/// Every backend path the driver app talks to.
///
/// These mirror `SaaradhiGo-backend/servers/*/urls.py` exactly. Nothing here
/// is a new endpoint — the driver app is a client of the existing API, and any
/// path in this file that does not already exist server-side is a bug here,
/// not a gap there.
class ApiEndpoints {
  const ApiEndpoints._();

  // --- auth (servers/auth_user/urls.py) ---
  static const String requestOtp = '/auth/otp/';
  static const String login = '/auth/login/';
  static const String refresh = '/auth/refresh/';
  static const String logout = '/auth/logout/';
  static const String userProfile = '/auth/profile/';
  static const String updateUser = '/auth/update/';

  // --- driver (servers/driver/urls.py) ---
  // Note the doubled segment: the driver app is mounted at /driver/ and the
  // profile routes are themselves under driver/.
  static const String driverProfile = '/driver/driver/profile/';
  static const String driverUpdate = '/driver/driver/update/';
  static const String earnings = '/driver/earnings/';
  static const String earningsSummary = '/driver/earnings/summary/';
  static const String withdrawalBalance = '/driver/withdrawals/balance/';
  static const String withdrawalRequest = '/driver/withdrawals/request/';
  static const String withdrawalHistory = '/driver/withdrawals/history/';
  static const String withdrawalBlockStatus = '/driver/withdrawals/block-status/';
  static const String vehicles = '/driver/vehicles/';
  static const String vehicleAdd = '/driver/vehicles/add/';
  static String vehicle(int id) => '/driver/vehicles/$id/';

  // --- ride (servers/ride/urls.py) ---
  static const String driverHistory = '/ride/driver-history/';
  static const String activeTrip = '/ride/active/';
  static String tripDetail(int tripId) => '/ride/trip/$tripId/';
  static String tripDriverDetails(int tripId) => '/ride/trip/$tripId/details/';
  static String driverCancelTrip(int tripId) => '/ride/trip/$tripId/driver-cancel/';
  static String tripChat(int tripId) => '/ride/trip/$tripId/chat/';
  static String receiptPdf(int tripId) => '/ride/trip/$tripId/receipt/pdf/';
  static const String mapsDirections = '/ride/maps/directions';

  // --- safety + support ---
  static const String sos = '/sos/';
  static const String supportTickets = '/support/tickets/';
  static const String supportCreateTicket = '/support/tickets/create/';
  static String supportTicket(int id) => '/support/tickets/$id/';
  static String supportTicketMessages(int id) => '/support/tickets/$id/messages/';

  // --- misc ---
  static const String config = '/config/';

  // --- websockets (servers/routing.py) ---
  /// Driver presence + location + incoming offers. Auth is a query-string
  /// token, and the server requires an opening lat/lng.
  static String driverLocationSocket({
    required String token,
    required double lat,
    required double lng,
  }) =>
      '/driver/location/?token=$token&lat=$lat&lng=$lng';

  static String tripSocket({required int tripId, required String token}) =>
      '/ride/trip/$tripId/?token=$token';

  static String tripChatSocket({required int tripId, required String token}) =>
      '/ride/trip/$tripId/chat/?token=$token';
}
