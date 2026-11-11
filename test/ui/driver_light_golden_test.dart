// Tier 1: the same screens in the LIGHT palette (the driver's daytime theme
// under Automatic). Regenerate with:
//   flutter test --update-goldens test/ui/driver_light_golden_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/storage/secure_storage_service.dart';
import 'package:saaradhigo_driver/core/theme/app_theme.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/features/auth/domain/auth_repository.dart';
import 'package:saaradhigo_driver/features/auth/presentation/login_mobile_screen.dart';
import 'package:saaradhigo_driver/ui/incoming_offer_card.dart';
import 'package:saaradhigo_driver/ui/sg_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/driver_ui_fixtures.dart';

/// Same 1% tolerance as the dark goldens: Windows-made goldens, Linux CI.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= 0.01) return true;
    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}

class _QuietAuth implements AuthRepository {
  @override
  Future<void> requestOtp(String phoneNumber) async {}
  @override
  Future<UserModel?> verifyOtp(String phoneNumber, String otp) async => null;
  @override
  Future<UserModel?> emailLogin({
    required String email,
    required String password,
  }) async => null;
  @override
  Future<String> requestPasswordReset(String email) async => '';
  @override
  Future<void> logout() async {}
}

Widget _light(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightTheme,
  home: Scaffold(backgroundColor: SgColors.bg000, body: child),
);

Future<void> _shoot(WidgetTester tester, Widget app, String name) async {
  setPhoneSurface(tester);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pump(const Duration(milliseconds: 300));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    goldenFileComparator = _TolerantComparator(
      (goldenFileComparator as LocalFileComparator).basedir.resolve(
        'driver_light_golden_test.dart',
      ),
    );
    await loadSgFonts();
  });

  setUp(() {
    SgColors.use(SgPalette.light);
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    SecureStorageService.resetSessionRevocationCacheForTests();
  });
  tearDown(() => SgColors.use(SgPalette.dark));

  testWidgets('home online, light', (t) async {
    await _shoot(t, _light(homeFrame(online: true)), 'light_home_online');
  });

  testWidgets('incoming offer, light', (t) async {
    setPhoneSurface(t);
    addTearDown(t.view.reset);
    await t.pumpWidget(
      _light(
        IncomingOfferCard(
          payload: sampleOfferWithEarning,
          alert: false,
          mapProvider: kPlaceholderMaps,
          onAccept: () {},
          onDecline: () {},
          onExpired: () {},
        ),
      ),
    );
    await t.pump(const Duration(seconds: 6));
    await t.pump(const Duration(milliseconds: 900));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/light_incoming_offer.png'),
    );
  });

  testWidgets('sign in, light', (t) async {
    await _shoot(
      t,
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(_QuietAuth())],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const LoginMobileScreen(),
        ),
      ),
      'light_sign_in',
    );
  });
}
