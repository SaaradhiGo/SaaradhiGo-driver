import '../../../../domain/models/user_model.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthUnauthenticated extends AuthState {
  final String? reason;

  const AuthUnauthenticated({this.reason});
}

class AuthRequestingOtp extends AuthState {
  const AuthRequestingOtp();
}

class AuthOtpSent extends AuthState {
  final String phoneNumber;
  const AuthOtpSent({required this.phoneNumber});
}

class AuthVerifyingOtp extends AuthState {
  final String phoneNumber;
  const AuthVerifyingOtp({required this.phoneNumber});
}

/// Email + password is in flight. A separate state from the OTP ones because
/// the UI shows a different form and must not light up the OTP spinner.
class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

class AuthAuthenticated extends AuthState {
  final UserModel? user;
  const AuthAuthenticated({this.user});
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
}
