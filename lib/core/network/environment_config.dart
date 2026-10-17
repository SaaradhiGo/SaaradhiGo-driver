import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Where this build points, and how it decides.
///
/// WHAT CHANGED AND WHY
/// --------------------
/// This used to be three lines:
///
///     await dotenv.load(fileName: ".env");
///     dotenv.env['API_BASE_URL'] ?? 'https://dev.api.saaradhigo.in/'
///
/// with `.env` declared as a Flutter **asset** in pubspec.yaml. Two problems,
/// one of which is a security issue and the other of which is worse:
///
///   1. **A bundled asset is not private.** Anything listed under `assets:`
///      is packed into the APK and can be extracted with `unzip`. `.env`
///      holds only URLs and a feature flag today, but the pattern invites a
///      key being added to it, and nothing would warn anyone. The rider app
///      removed exactly this for exactly this reason.
///
///   2. **A missing or stale `.env` silently pointed a release build at
///      dev.** `?? 'https://dev.api.saaradhigo.in/'` is a fallback that
///      cannot fail loudly: a store build with no `.env` would talk to test
///      data, against drivers who are not there, with nothing on screen to
///      say so. `.env` is gitignored, so CI never had one.
///
/// RESOLUTION ORDER, highest first
/// -------------------------------
///   1. `--dart-define` — compile-time, cannot be swapped after the build
///   2. `.env` via dotenv, when a developer has loaded one locally
///   3. the dev host — **DEBUG BUILDS ONLY**
///
/// A release build that resolves to nothing, or to a dev/staging/qa/localhost
/// host, reports [misconfiguration]; `main()` renders that message instead of
/// starting the app. Pass [allowNonProductionHost] to build a release binary
/// for QA on purpose -- it then runs, with a QA banner on every screen.
///
/// Build for production with:
///   flutter build apk --release \
///     --dart-define=API_BASE_URL=https://api.saaradhigo.in/api/v1/ \
///     --dart-define=WS_BASE_URL=wss://api.saaradhigo.in/ws
class EnvironmentConfig {
  const EnvironmentConfig._();

  static const String _defineApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _defineWsBaseUrl = String.fromEnvironment('WS_BASE_URL');

  static const String _devApiBaseUrl = 'https://dev.api.saaradhigo.in/';
  static const String _devWsBaseUrl = 'wss://dev.api.saaradhigo.in/';

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// Lets a RELEASE build point at a non-production server on purpose.
  ///
  /// A QA acceptance build has to be a real release build -- minified,
  /// shrunk, signed, the same code path a driver runs -- while talking to the
  /// QA API. Without this flag [misconfiguration] refuses exactly that build,
  /// so QA would have to certify a debug binary and hope.
  ///
  /// It does NOT weaken the guard it opens:
  ///   * a release build with no server configured at all is still refused,
  ///     because an unconfigured build is a mistake in every environment;
  ///   * the flag is compile-time, so a store build cannot acquire it later;
  ///   * [environmentLabel] still reports 'non-production', and the app shows
  ///     a QA banner, so such a build cannot be mistaken for the real one.
  ///
  ///   flutter build apk --release   ///     --dart-define=ALLOW_NON_PRODUCTION_HOST=true   ///     --dart-define=API_BASE_URL=https://dev.api.saaradhigo.in/ ...
  static const bool allowNonProductionHost = bool.fromEnvironment(
    'ALLOW_NON_PRODUCTION_HOST',
  );

  /// Load a local `.env` if the developer has one. Never throws.
  ///
  /// `.env` is no longer a declared asset, so on a device this simply finds
  /// nothing and the `--dart-define` values are used. It stays supported for
  /// `flutter run` on a developer's machine, where an asset is not involved.
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } on Object {
      // No .env, or it is not bundled. Expected on every CI and store build.
    }
  }

  /// Reads dotenv without throwing when nothing was ever loaded.
  static String _fromDotenv(String key) {
    try {
      return dotenv.isInitialized ? (dotenv.env[key] ?? '') : '';
    } on Object {
      return '';
    }
  }

  static String _resolve(String define, String key, String devFallback) {
    if (define.isNotEmpty) return define;
    final fromFile = _fromDotenv(key);
    if (fromFile.isNotEmpty) return fromFile;
    // Deliberately empty in release: see [misconfiguration].
    return isProduction ? '' : devFallback;
  }

  static String get apiBaseUrl =>
      _resolve(_defineApiBaseUrl, 'API_BASE_URL', _devApiBaseUrl);

  static String get wsBaseUrl =>
      _resolve(_defineWsBaseUrl, 'WS_BASE_URL', _devWsBaseUrl);

  /// Hosts that must never appear in a release build.
  static const List<String> _nonProductionMarkers = <String>[
    'dev.',
    'staging.',
    'qa.',
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  ];

  /// Why this build must not run, or null when it is fine.
  ///
  /// Only ever non-null in a release build. A debug build is allowed to point
  /// anywhere, which is the point of a debug build.
  static String? get misconfiguration => evaluate(
    isProduction: isProduction,
    allowNonProductionHost: allowNonProductionHost,
    api: apiBaseUrl,
    ws: wsBaseUrl,
  );

  /// The decision itself, with every input passed in.
  ///
  /// Separated from [misconfiguration] because the inputs there are
  /// compile-time constants: `dart.vm.product` is false under `flutter test`,
  /// so the release branches could only ever be exercised by building a
  /// release binary and looking at it. A guard nobody can test is a guard
  /// nobody can trust.
  @visibleForTesting
  static String? evaluate({
    required bool isProduction,
    required bool allowNonProductionHost,
    required String api,
    required String ws,
  }) {
    if (!isProduction) return null;

    if (api.isEmpty || ws.isEmpty) {
      // Checked BEFORE the opt-in: an unconfigured release build is a mistake
      // in every environment, and ALLOW_NON_PRODUCTION_HOST does not mean
      // "allow no host at all".
      return 'This build has no server configured. It was compiled without '
          '--dart-define=API_BASE_URL and --dart-define=WS_BASE_URL.';
    }

    if (allowNonProductionHost) {
      // Deliberate QA build. The banner says so on every screen.
      return null;
    }

    for (final marker in _nonProductionMarkers) {
      if (api.contains(marker) || ws.contains(marker)) {
        return 'This build points at a non-production server ($marker). It '
            'must not be distributed.';
      }
    }
    return null;
  }

  /// Short label for diagnostics and the QA build banner.
  static String get environmentLabel {
    final api = apiBaseUrl;
    if (api.isEmpty) return 'unconfigured';
    for (final marker in _nonProductionMarkers) {
      if (api.contains(marker)) return 'non-production';
    }
    return isProduction ? 'production' : 'debug';
  }
}
