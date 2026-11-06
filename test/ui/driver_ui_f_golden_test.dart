// Goldens at 390x844 logical. Regenerate with:
//   flutter test --update-goldens test/ui/driver_ui_f_golden_test.dart
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
import 'package:saaradhigo_driver/features/auth/presentation/otp_verification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/driver_ui_fixtures.dart';

/// Same 1% tolerance as groups D and E: Windows-made goldens, Linux CI.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
        imageBytes, await getGoldenBytes(golden));
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
  Future<UserModel?> emailLogin(
          {required String email, required String password}) async =>
      null;
  @override
  Future<String> requestPasswordReset(String email) async => '';
  @override
  Future<void> logout() async {}
}

Future<void> shoot(WidgetTester tester, Widget screen, String name) async {
  setPhoneSurface(tester);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(_QuietAuth())],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: screen,
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  await expectLater(
      find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  setUpAll(() async {
    goldenFileComparator = _TolerantComparator(
        (goldenFileComparator as LocalFileComparator)
            .basedir
            .resolve('driver_ui_f_golden_test.dart'));
    await loadSgFonts();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    SecureStorageService.resetSessionRevocationCacheForTests();
  });

  testWidgets('sign in', (t) => shoot(t, const LoginMobileScreen(), 'sign_in'));

  testWidgets('enter the code', (t) async {
    await shoot(
        t, const OtpVerificationScreen(phoneNumber: '+919876543210'), 'otp');
    // Leave the resend countdown's timer finished.
    await t.pumpWidget(const SizedBox());
  });
}
