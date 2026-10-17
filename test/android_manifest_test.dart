// The manifest must parse, and it must satisfy Android 14's foreground-service
// rules, or the driver app crashes the moment a driver goes on duty.
//
// WHY A TEXT TEST
// ---------------
// Neither `flutter test` nor `flutter analyze` reads AndroidManifest.xml, and
// an APK build succeeds with a manifest that is fatal at runtime. On the
// rebuild branch this file was unparseable for some time -- a double hyphen
// inside an XML comment, which XML forbids -- and every APK build failed with
// `ManifestMerger2$MergeFailureException` while the Dart suite stayed green.
// The Android 14 service-type requirement is worse: it builds, installs, and
// throws only when startForeground() runs on a real API 34+ phone.
//
// These assertions are deliberately crude. A real build plus a device is the
// only complete check; this one fails in under a second and says why.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');

  test('the Android manifest exists', () {
    expect(manifest.existsSync(), isTrue,
        reason: 'android/app/src/main/AndroidManifest.xml is missing');
  });

  test('the Android manifest is well-formed XML', () {
    expect(
      () => XmlDocument.parse(manifest.readAsStringSync()),
      returnsNormally,
      reason: 'the manifest does not parse, so no APK can be built',
    );
  });

  test('no comment contains a double hyphen', () {
    // The specific trap, checked directly so the failure message names it.
    // XML forbids `--` inside a comment, and it is easy to reintroduce by
    // pasting a command line into an explanation.
    final text = manifest.readAsStringSync();
    final comments = RegExp(r'<!--(.*?)-->', dotAll: true).allMatches(text);
    for (final c in comments) {
      final body = c.group(1)!;
      expect(
        body.contains('--'),
        isFalse,
        reason: 'a double hyphen inside an XML comment makes the whole manifest '
            'unparseable and every APK build fail. Offending comment starts: '
            '${body.trim().split('\n').first}',
      );
    }
  });

  test('the app declares the permissions a driver app needs', () {
    final declared = _permissions(manifest);

    // Location is the whole job. Without these a driver cannot be dispatched
    // to and no trip can be tracked.
    expect(declared, contains('android.permission.ACCESS_FINE_LOCATION'));
    expect(declared, contains('android.permission.INTERNET'));
  });

  test('the location service declares foregroundServiceType="location"', () {
    // Android 14 (API 34) requirement. startForeground() for a location
    // service whose manifest declares no type throws
    // MissingForegroundServiceTypeException, so the driver app crashes the
    // moment a driver goes on duty on a modern phone.
    //
    // This app tracks location through geolocator, whose plugin manifest
    // declares GeolocatorLocationService WITHOUT a type, so the app manifest
    // has to declare it again and add the attribute. Any replacement location
    // plugin has to do the same, hence the second, name-agnostic assertion.
    final doc = XmlDocument.parse(manifest.readAsStringSync());
    final services = doc.findAllElements('service').toList();

    final geolocator = services.where(
      (e) => (e.getAttribute('android:name') ?? '')
          .endsWith('geolocator.GeolocatorLocationService'),
    );

    expect(
      geolocator,
      isNotEmpty,
      reason: 'the app must re-declare the geolocator service so it can add '
          'the Android 14 foregroundServiceType attribute',
    );
    expect(
      geolocator.first.getAttribute('android:foregroundServiceType'),
      'location',
      reason: 'without foregroundServiceType="location" going on duty throws '
          'MissingForegroundServiceTypeException on Android 14+',
    );

    // Name-agnostic: whatever the plugin is called, SOME declared service must
    // carry the location type, or background tracking cannot run at all.
    expect(
      services.any((e) =>
          (e.getAttribute('android:foregroundServiceType') ?? '')
              .contains('location')),
      isTrue,
      reason: 'no declared service has foregroundServiceType="location"',
    );
  });

  test('the permissions that foreground location needs are declared', () {
    final declared = _permissions(manifest);

    // All three are required together on API 34: the type in the service
    // declaration is checked against a matching FOREGROUND_SERVICE_* grant.
    expect(declared, contains('android.permission.FOREGROUND_SERVICE'));
    expect(
        declared, contains('android.permission.FOREGROUND_SERVICE_LOCATION'));
    expect(declared, contains('android.permission.ACCESS_BACKGROUND_LOCATION'));
  });

  test('no API key or password is committed in the manifest', () {
    final text = manifest.readAsStringSync();
    // The rider app shipped a literal AIza... Maps key in its manifest from
    // its initial commit, which is why that key has to be rotated. This app
    // renders maps with flutter_map over OSM tiles and needs no Google Maps
    // key at all; this assertion keeps it that way.
    expect(text, isNot(contains('AIza')),
        reason: 'a Google API key is committed in the manifest');
    expect(text, isNot(contains('com.google.android.geo.API_KEY')),
        reason: 'this app uses flutter_map/OSM and must not acquire a '
            'dependency on a Google Maps key');
    expect(text.toLowerCase(), isNot(matches(RegExp(r'password\s*='))),
        reason: 'a password appears in the manifest');
  });

  test('every manifest placeholder is supplied by Gradle', () {
    // An unsupplied ${PLACEHOLDER} is a build failure, so the two files have
    // to agree. Nothing but ${applicationName} is used today; this guards the
    // next one somebody adds.
    final text = manifest.readAsStringSync();
    final placeholders = RegExp(r'\$\{([A-Za-z_][A-Za-z0-9_]*)\}')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .where((n) => n != 'applicationName') // supplied by the Flutter plugin
        .toSet();

    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    for (final name in placeholders) {
      expect(
        gradle.contains('manifestPlaceholders["$name"]'),
        isTrue,
        reason: 'the manifest uses \${$name} and build.gradle.kts does not '
            'define it; an unsupplied placeholder fails the build',
      );
    }
  });
}

Set<String> _permissions(File manifest) => XmlDocument.parse(
      manifest.readAsStringSync(),
    )
        .findAllElements('uses-permission')
        .map((e) => e.getAttribute('android:name'))
        .whereType<String>()
        .toSet();
