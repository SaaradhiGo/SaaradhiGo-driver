/// The base URL plus an endpoint constant has to be a route the server serves.
///
/// THE DEFECT THIS CLOSES
/// ----------------------
/// `base/urls.py` routes the whole API at `path('api/v1/', include(api_urls))`.
/// Every constant in `ApiEndpoints` is a bare path -- `/auth/otp/`,
/// `/driver/driver/profile/` -- that Dio appends to `baseUrl`.
///
/// The base URL was `https://dev.api.saaradhigo.in/`, with no `/api/v1`. So
/// every REST request in the app resolved to
/// `https://dev.api.saaradhigo.in/auth/otp/`, which is not a routed path:
/// **every REST call 404d**. The app's own comment in `api_endpoints.dart`
/// says "the full route is /api/v1/driver/driver/incentives/", so the
/// prefix was known and simply not in the base.
///
/// It survived because the app had never been exercised end to end against
/// the live API: unit tests stub the adapter and assert `options.path`, which
/// is the path *relative to* the base, so the missing prefix is invisible to
/// every one of them.
///
/// THE WEBSOCKET CONVENTION IS THE OPPOSITE, AND THAT IS A TRAP
/// ------------------------------------------------------------
/// This app's socket constants already carry the prefix
/// (`ws/driver/location/`), concatenated straight onto the WS base -- so the
/// WS base must NOT contain `ws`. The RIDER app does it the other way: its
/// base ends in `/ws` and its paths do not. Copying one app's value into the
/// other yields `/wsws/...`, which is exactly what happened to this app's
/// production WS value in a build script.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/core/network/environment_config.dart';

/// Routes the backend actually serves, from servers/*/urls.py, under
/// `api/v1/`.
const _knownRestRoutes = <String>[
  '/auth/otp/',
  '/auth/login/',
  '/auth/refresh/',
  '/auth/logout/',
  '/auth/profile/',
  '/auth/update/',
  '/ride/active/',
  '/ride/rate-trip/',
  '/driver/driver/profile/',
  '/driver/driver/incentives/',
  '/driver/earnings/summary/',
  '/support/tickets/create/',
];

void main() {
  group('the REST base URL', () {
    test('ends in the /api/v1/ prefix the server routes the API at', () {
      final base = EnvironmentConfig.apiBaseUrl;

      expect(base, isNotEmpty);
      expect(
        base,
        contains('/api/v1'),
        reason: 'without this prefix every REST call in the app 404s',
      );
      expect(
        base,
        endsWith('/'),
        reason:
            'endpoint constants begin with "/", so the base must end '
            'with one or the joined path doubles the slash',
      );
    });

    test('joining it with each endpoint yields an /api/v1/ route', () {
      final base = EnvironmentConfig.apiBaseUrl;

      for (final route in _knownRestRoutes) {
        final joined = Uri.parse(base).resolve('.$route').toString();
        expect(
          joined,
          contains('/api/v1$route'),
          reason: '$route does not resolve to a served path',
        );
      }
    });

    test('it is not the bare host that used to be configured', () {
      // The exact value that could never work.
      expect(
        EnvironmentConfig.apiBaseUrl,
        isNot('https://dev.api.saaradhigo.in/'),
      );
    });
  });

  group('the WebSocket base URL', () {
    test('does NOT carry a ws prefix, because the paths already do', () {
      final base = EnvironmentConfig.wsBaseUrl;

      expect(base, isNotEmpty);
      expect(base, endsWith('/'));
      // `wss://host/` is fine; `wss://host/ws` is not, because
      // ApiEndpoints.wsDriverLocation is already 'ws/driver/location/'.
      expect(
        Uri.parse(base).path.replaceAll('/', ''),
        isEmpty,
        reason:
            'this app concatenates "ws/..." onto the base, so a base '
            'that also contains "ws" produces /wsws/...',
      );
    });

    test('the socket paths carry it instead', () {
      expect(ApiEndpoints.wsDriverLocation, startsWith('ws/'));
      expect(ApiEndpoints.wsTripStatus('7'), startsWith('ws/'));
      expect(ApiEndpoints.wsTripChat('7'), startsWith('ws/'));
    });

    test('joining base and path gives the route the server serves', () {
      final joined =
          '${EnvironmentConfig.wsBaseUrl}'
          '${ApiEndpoints.wsDriverLocation}';

      expect(joined, contains('/ws/driver/location/'));
      expect(joined, isNot(contains('wsws')));
      expect(joined, isNot(contains('/ws/ws/')));
    });
  });

  group('the build script agrees with the app', () {
    late String script;

    setUpAll(() {
      final file = File('tool/build_release.sh');
      expect(file.existsSync(), isTrue);
      script = file.readAsStringSync();
    });

    String value(String name) {
      final match = RegExp(
        '^$name="([^"]+)"',
        multiLine: true,
      ).firstMatch(script);
      if (match == null) fail('tool/build_release.sh has no $name');
      return match.group(1)!;
    }

    test('both REST targets carry /api/v1', () {
      // A QA artifact built without the prefix is an app in which nothing
      // works, and the failure looks like a backend outage.
      for (final name in ['QA_API', 'PROD_API']) {
        expect(
          value(name),
          contains('/api/v1'),
          reason: '$name would produce an app where every call 404s',
        );
        expect(value(name), endsWith('/'));
      }
    });

    test('neither WS target carries a ws path segment', () {
      for (final name in ['QA_WS', 'PROD_WS']) {
        final uri = Uri.parse(value(name));
        expect(
          uri.path.replaceAll('/', ''),
          isEmpty,
          reason:
              '$name uses the RIDER app convention; this app would '
              'build /wsws/driver/location/',
        );
      }
    });

    test('QA points at the QA host and production at the production host', () {
      expect(value('QA_API'), contains('dev.api.saaradhigo.in'));
      expect(value('QA_WS'), contains('dev.api.saaradhigo.in'));
      expect(value('PROD_API'), isNot(contains('dev.')));
      expect(value('PROD_WS'), isNot(contains('dev.')));
    });
  });

  group('.env.example describes a working configuration', () {
    test('its API_BASE_URL carries the prefix too', () {
      // A developer who copies this file gets an app where nothing works.
      final file = File('.env.example');
      if (!file.existsSync()) return;
      final text = file.readAsStringSync();

      final match = RegExp(
        r'^API_BASE_URL=(.+)$',
        multiLine: true,
      ).firstMatch(text);
      expect(match, isNotNull);
      expect(match!.group(1)!.trim(), contains('/api/v1'));
    });
  });
}
