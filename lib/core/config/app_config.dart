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
///
/// A RELEASE build that omits those, or that points at a dev/staging/localhost
/// host, refuses to start and says why -- see [misconfiguration]. Previously the
/// defaults pointed at QA, so a forgotten flag shipped a store build talking to
/// test data, with nothing in the app to indicate it. Debug builds keep the QA
/// fallback so local development needs no flags.
class AppConfig {
  const AppConfig._();

  /// Raw build-time values. Empty when the build did not supply them, which is
  /// the case this class exists to catch.
  static const String _rawApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _rawWsBaseUrl = String.fromEnvironment('WS_BASE_URL');

  /// Convenience fallbacks for DEBUG builds only.
  ///
  /// A developer running `flutter run` with no flags should get the QA stack, not
  /// an error. A release build gets no such courtesy -- see [misconfiguration].
  static const String _devApiBaseUrl = 'https://dev.api.saaradhigo.in/api/v1';
  static const String _devWsBaseUrl = 'wss://dev.api.saaradhigo.in/ws';

  static String get apiBaseUrl =>
      _rawApiBaseUrl.isNotEmpty ? _rawApiBaseUrl : (isProduction ? '' : _devApiBaseUrl);

  static String get wsBaseUrl =>
      _rawWsBaseUrl.isNotEmpty ? _rawWsBaseUrl : (isProduction ? '' : _devWsBaseUrl);

  /// Hosts that must never appear in a release build.
  ///
  /// Shipping a store build that talks to QA is worse than shipping one that does
  /// not start: real drivers would accept real-looking rides against test data,
  /// and nothing in the app would say so.
  static const List<String> _nonProductionMarkers = <String>[
    'dev.',
    'staging.',
    'qa.',
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  ];

  /// Why this build must refuse to start, or null when it is configured sanely.
  ///
  /// Only ever non-null for a RELEASE build. Debug builds are left alone so local
  /// development does not need flags.
  static String? get misconfiguration {
    if (!isProduction) return null;
    if (_rawApiBaseUrl.isEmpty || _rawWsBaseUrl.isEmpty) {
      return 'This release build was compiled without API_BASE_URL and '
          'WS_BASE_URL. Rebuild with --dart-define for the target environment.';
    }
    final offending = _nonProductionMarkers.where(
      (m) => _rawApiBaseUrl.contains(m) || _rawWsBaseUrl.contains(m),
    );
    if (offending.isNotEmpty) {
      return 'This release build points at a non-production host '
          '("${offending.first}"). Rebuild with the production URLs.';
    }
    return null;
  }

  /// Short label for the environment, shown on any build that is not production.
  ///
  /// A QA build in somebody's hand should be identifiable without asking.
  static String get environmentLabel {
    if (_rawApiBaseUrl.isEmpty) return isProduction ? 'UNCONFIGURED' : 'LOCAL/QA';
    for (final marker in _nonProductionMarkers) {
      if (_rawApiBaseUrl.contains(marker)) {
        return marker == 'dev.' ? 'QA' : marker.replaceAll('.', '').toUpperCase();
      }
    }
    return 'PRODUCTION';
  }

  /// True when this build should wear a visible environment badge.
  static bool get showEnvironmentBadge => environmentLabel != 'PRODUCTION';

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
