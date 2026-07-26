/// Compile-time configuration.
///
/// Values come from `--dart-define` so a release build cannot accidentally
/// ship a developer's host, and so nothing secret has to live in an asset
/// bundled into the APK. The rider app learned this the hard way: its Google
/// Maps key shipped inside `assets/.env`, which anyone who downloads the APK
/// can extract.
///
/// Build with:
///   flutter build apk --dart-define=API_BASE_URL=https://api.saaradhigo.in/api/v1 \
///                     --dart-define=WS_BASE_URL=wss://api.saaradhigo.in/ws
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dev.api.saaradhigo.in/api/v1',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://dev.api.saaradhigo.in/ws',
  );

  /// How often the app pushes a location frame while on duty.
  ///
  /// The server's presence heartbeat has a 45s TTL and its sweeper runs every
  /// 60s, so anything slower than ~20s risks the driver being swept out of the
  /// geo index mid-shift and going invisible to dispatch.
  static const Duration locationInterval = Duration(seconds: 10);

  /// Minimum movement before an out-of-band location push. A stationary driver
  /// still sends on [locationInterval] to hold the heartbeat.
  static const int locationDistanceFilterMeters = 25;

  /// How long a driver has to accept an offer before the card self-dismisses.
  /// The server auto-cancels an unaccepted trip at 90s and dispatches in 20s
  /// waves, so 20s here keeps the card in step with the wave that produced it.
  static const Duration offerTimeout = Duration(seconds: 20);

  /// WebSocket reconnect backoff bounds.
  static const Duration wsMinBackoff = Duration(seconds: 1);
  static const Duration wsMaxBackoff = Duration(seconds: 30);

  /// Network timeouts. Deliberately short on connect: a driver on a weak
  /// tower should see a retry button quickly, not a 60-second spinner.
  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
}
