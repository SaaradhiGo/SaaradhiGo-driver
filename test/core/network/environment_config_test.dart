/// A release build must know which server it talks to, or refuse to run.
///
/// THE DEFECT THIS LOCKS DOWN
/// --------------------------
/// `EnvironmentConfig` resolved the API host as
/// `dotenv.env['API_BASE_URL'] ?? 'https://dev.api.saaradhigo.in/'`, with
/// `.env` declared as a bundled Flutter asset. Two problems: the asset shipped
/// inside the APK where `unzip` reaches it, and the `??` fallback could not
/// fail loudly — a store build with no `.env` talked to **dev**, showing a
/// driver a working app full of test data with nothing on screen to say so.
///
/// The replacement refuses that build. These tests cover the refusal, because
/// `misconfiguration` reads compile-time constants — `dart.vm.product` is
/// false under `flutter test` — so without `evaluate()` taking its inputs
/// explicitly, the release branches could only be exercised by building a
/// release binary and looking at it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/environment_config.dart';
import 'package:saaradhigo_driver/main.dart';

const _prodApi = 'https://api.saaradhigo.in/api/v1/';
const _prodWs = 'wss://api.saaradhigo.in/ws';
const _qaApi = 'https://dev.api.saaradhigo.in/';
const _qaWs = 'wss://dev.api.saaradhigo.in/';

String? evaluate({
  bool isProduction = true,
  bool allowNonProductionHost = false,
  String api = _prodApi,
  String ws = _prodWs,
}) => EnvironmentConfig.evaluate(
  isProduction: isProduction,
  allowNonProductionHost: allowNonProductionHost,
  api: api,
  ws: ws,
);

void main() {
  group('a debug build may point anywhere', () {
    test('no complaint, whatever it is pointed at', () {
      expect(evaluate(isProduction: false, api: _qaApi, ws: _qaWs), isNull);
      expect(
        evaluate(
          isProduction: false,
          api: 'http://10.0.2.2:8000/',
          ws: 'ws://x',
        ),
        isNull,
      );
      expect(evaluate(isProduction: false, api: '', ws: ''), isNull);
    });
  });

  group('a release build with nothing configured', () {
    test('is refused, and says what is missing', () {
      final problem = evaluate(api: '', ws: '');

      expect(problem, isNotNull);
      expect(problem, contains('no server configured'));
      expect(problem, contains('API_BASE_URL'));
    });

    test('is refused even when only the websocket is missing', () {
      expect(evaluate(ws: ''), contains('no server configured'));
    });

    test('is refused even with the QA opt-in set', () {
      // ALLOW_NON_PRODUCTION_HOST means "QA on purpose", not "no host at all".
      // An unconfigured release build is a mistake in every environment.
      expect(
        evaluate(allowNonProductionHost: true, api: '', ws: ''),
        contains('no server configured'),
      );
    });
  });

  group('a release build pointed at a non-production host', () {
    test('is refused for every marker', () {
      for (final host in const [
        'https://dev.api.saaradhigo.in/',
        'https://staging.api.saaradhigo.in/',
        'https://qa.api.saaradhigo.in/',
        'http://localhost:8000/',
        'http://127.0.0.1:8000/',
        'http://10.0.2.2:8000/',
      ]) {
        expect(
          evaluate(api: host),
          isNotNull,
          reason: 'a release build must not ship pointed at $host',
        );
      }
    });

    test('is refused when only the websocket is non-production', () {
      // The pair has to be checked together: an app talking to production REST
      // and a dev socket is a real and confusing half-configuration.
      expect(evaluate(ws: _qaWs), isNotNull);
    });

    test('names the marker it objected to', () {
      expect(evaluate(api: _qaApi), contains('dev.'));
    });
  });

  group('the deliberate QA release build', () {
    test('is allowed when the opt-in is set', () {
      // A QA acceptance build has to be a REAL release build -- minified,
      // shrunk, signed -- talking to QA. Otherwise QA certifies a debug
      // binary and hopes.
      expect(
        evaluate(allowNonProductionHost: true, api: _qaApi, ws: _qaWs),
        isNull,
      );
    });

    test('a production build is unaffected either way', () {
      expect(evaluate(), isNull);
      expect(evaluate(allowNonProductionHost: true), isNull);
    });
  });

  group('the opt-in cannot be acquired after the build', () {
    test('it is off unless compiled in', () {
      // bool.fromEnvironment is compile-time: nothing at runtime can set it,
      // which is what makes it safe to ship the flag at all.
      expect(EnvironmentConfig.allowNonProductionHost, isFalse);
    });
  });

  group('environmentLabel', () {
    test(
      'reports non-production for the dev host this test run resolves to',
      () {
        // With no dart-defines and no .env, a debug run falls back to the dev
        // host -- so the label must say so, because it drives the QA banner.
        expect(EnvironmentConfig.environmentLabel, 'non-production');
      },
    );
  });

  group('the refusal screen', () {
    testWidgets('shows the reason rather than a blank app', (tester) async {
      await tester.pumpWidget(
        const MisconfiguredApp(message: 'This build has no server configured.'),
      );

      expect(find.text('This build cannot be used'), findsOneWidget);
      expect(find.text('This build has no server configured.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('tells the driver what to do next', (tester) async {
      await tester.pumpWidget(const MisconfiguredApp(message: 'x'));

      expect(
        find.textContaining('report this to the SaaradhiGo team'),
        findsOneWidget,
      );
    });
  });
}
