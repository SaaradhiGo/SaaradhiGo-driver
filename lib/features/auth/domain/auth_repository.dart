import 'auth_user.dart';

/// Contract the presentation layer depends on.
///
/// Screens and controllers never touch Dio, endpoints, or JSON — swapping the
/// transport (or faking it in a widget test) means providing a different
/// implementation of this, nothing more.
abstract class AuthRepository {
  /// Ask the server to SMS an OTP. `role: 'driver'` matters: the backend
  /// creates a Driver profile on first login for that role.
  Future<void> requestOtp(String phoneNumber);

  /// Exchange the OTP for tokens and persist them. `deviceToken` is the FCM
  /// token, stored server-side so dispatch can push ride offers.
  Future<AuthUser> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? deviceToken,
  });

  Future<AuthUser> fetchProfile();

  Future<AuthUser> updateProfile({String? fullName, String? email});

  /// Blacklists the refresh token server-side, then clears local state.
  Future<void> logout();

  Future<bool> hasSession();
}
