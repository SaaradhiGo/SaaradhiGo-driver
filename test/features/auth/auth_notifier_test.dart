import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saaradhigo_driver/core/network/auth_session_events.dart';
import 'package:saaradhigo_driver/core/storage/secure_storage_service.dart';
import 'package:saaradhigo_driver/features/auth/domain/auth_repository.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_notifier.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_state.dart';

import 'package:saaradhigo_driver/domain/models/user_model.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> requestOtp(String phoneNumber) async {}

  @override
  Future<UserModel?> verifyOtp(String phoneNumber, String otp) async {
    await SecureStorageService.saveTokens(accessToken: 'a', refreshToken: 'r');
    return null;
  }

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'starts unknown and settles to unauthenticated without tokens',
    () async {
      expect(container.read(authNotifierProvider), isA<AuthUnknown>());
      await pumpEventQueue();
      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
    },
  );

  test('session-expired event ends an active session once', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final notifier = container.read(authNotifierProvider.notifier);

    await notifier.verifyOtp('+919876543210', '1234');
    expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());

    AuthSessionEvents.emitSessionExpired();
    await pumpEventQueue();

    final state = container.read(authNotifierProvider);
    expect(state, isA<AuthUnauthenticated>());
    expect((state as AuthUnauthenticated).reason, isNotNull);

    AuthSessionEvents.emitSessionExpired();
    await pumpEventQueue();

    expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
  });
}
