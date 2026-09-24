import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/app/misconfigured_build_screen.dart';
import 'package:saaradhigo_driver/core/config/app_config.dart';

/// A store build must not be able to talk to QA.
///
/// The defaults used to point at `dev.api.saaradhigo.in`, so a release build that
/// forgot its `--dart-define` flags shipped pointed at test data — and nothing in
/// the app said so. Real drivers would have gone online, accepted real-looking
/// offers and completed rides that counted for nothing.
///
/// These tests run in a DEBUG test binary, so `AppConfig.isProduction` is false and
/// the release-only refusal cannot be exercised directly here. What is asserted is
/// the part that holds in every build: the marker list is right, the environment
/// label is honest, the badge appears for non-production, and the refusal screen
/// renders its reason. The release behaviour itself is a one-line build check:
///
///   flutter build apk --release        -> must refuse to start
///   flutter build apk --release --dart-define=API_BASE_URL=https://dev...  -> refuse
///   flutter build apk --release --dart-define=API_BASE_URL=https://api...  -> run
void main() {
  group('environment labelling', () {
    test('a test binary is not production, so it keeps the QA fallback', () {
      // Guards the developer-convenience half of the contract: `flutter run` and
      // `flutter test` must work with no flags at all.
      expect(AppConfig.isProduction, isFalse);
      expect(AppConfig.apiBaseUrl, isNotEmpty,
          reason: 'a debug build must still have a usable base URL');
      expect(AppConfig.wsBaseUrl, isNotEmpty);
    });

    test('a debug build is never treated as misconfigured', () {
      // Otherwise every developer and every CI run would hit the refusal screen.
      expect(AppConfig.misconfiguration, isNull);
    });

    test('a non-production build is labelled and badged', () {
      expect(AppConfig.environmentLabel, isNot('PRODUCTION'));
      expect(AppConfig.showEnvironmentBadge, isTrue,
          reason: 'a tester holding two identical APKs must be able to tell '
              'which environment each one talks to');
    });

    test('the label never leaks a full URL', () {
      // It is rendered on screen; it should be a word, not an endpoint.
      expect(AppConfig.environmentLabel, isNot(contains('http')));
      expect(AppConfig.environmentLabel.length, lessThan(20));
    });
  });

  group('MisconfiguredBuildScreen', () {
    testWidgets('states the reason and that the build will not run',
        (tester) async {
      await tester.pumpWidget(const MisconfiguredBuildScreen(
        reason: 'This release build points at a non-production host ("dev.").',
      ));

      expect(find.text('Build not configured'), findsOneWidget);
      expect(find.textContaining('non-production host'), findsOneWidget);
      // The person holding the phone can do nothing about it, so say so plainly
      // rather than offering a retry that cannot work.
      expect(find.textContaining('will not run'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders inside a SafeArea so it is readable on a notched phone',
        (tester) async {
      await tester.pumpWidget(
        const MisconfiguredBuildScreen(reason: 'missing API_BASE_URL'),
      );
      expect(find.byType(SafeArea), findsOneWidget);
    });
  });

  group('EnvironmentBadge', () {
    testWidgets('shows the label over the app on a non-production build',
        (tester) async {
      await tester.pumpWidget(
        const EnvironmentBadge(
          child: MaterialApp(home: Scaffold(body: Text('app content'))),
        ),
      );

      expect(find.text('app content'), findsOneWidget);
      expect(find.text(AppConfig.environmentLabel), findsOneWidget);
    });

    testWidgets('the badge cannot swallow taps meant for the app',
        (tester) async {
      // A badge pinned over the top-right corner must not eat the button under
      // it -- that corner holds real controls on several screens.
      var taps = 0;
      await tester.pumpWidget(
        EnvironmentBadge(
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const SizedBox(width: 200, height: 100,
                      child: Text('tap target')),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(760, 20));
      await tester.pump();
      expect(taps, 1, reason: 'the badge must be IgnorePointer');
    });

    testWidgets('the badge is hidden from screen readers', (tester) async {
      // A driver using TalkBack should not hear "QA" before every screen.
      //
      // Asserted against the semantics tree rather than by counting
      // ExcludeSemantics widgets: MaterialApp ships its own, so a widget-type
      // count would pass or fail for reasons unrelated to the badge.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const EnvironmentBadge(
          child: MaterialApp(home: Scaffold(body: Text('content'))),
        ),
      );

      expect(find.text(AppConfig.environmentLabel), findsOneWidget,
          reason: 'the badge is still painted');
      expect(find.bySemanticsLabel(AppConfig.environmentLabel), findsNothing,
          reason: 'but a screen reader must not announce it');
      handle.dispose();
    });
  });
}
