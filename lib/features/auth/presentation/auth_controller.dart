import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/auth_user.dart';

enum AuthStatus { unknown, signedOut, signedIn }

@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.otpRequestedFor,
    this.isBusy = false,
    this.error,
  });

  final AuthStatus status;
  final AuthUser? user;

  /// The phone we last sent an OTP to. Held in state so the verify screen can
  /// survive a rebuild (or a rotation) without the number being passed
  /// around as a route argument.
  final String? otpRequestedFor;

  final bool isBusy;
  final Object? error;

  bool get isSignedIn => status == AuthStatus.signedIn;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? otpRequestedFor,
    bool? isBusy,
    Object? error,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        otpRequestedFor: otpRequestedFor ?? this.otpRequestedFor,
        isBusy: isBusy ?? this.isBusy,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Owns the session: who is signed in, and the OTP handshake.
///
/// Deliberately does NOT own the token lifecycle — [ApiClient] refreshes
/// transparently and only tells us when the refresh token is finally spent.
/// Keeping refresh out of here is why a driver never gets bounced to login
/// mid-trip just because 15 minutes elapsed.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Session-expired signal from the HTTP layer.
    ref.listen<int>(sessionExpiredProvider, (previous, next) {
      if ((previous ?? 0) < next) {
        // The refresh token is spent. Anything the driver was doing is over;
        // the router will bounce them to /login on the next frame.
        state = const AuthState(status: AuthStatus.signedOut);
      }
    });
    return const AuthState();
  }

  /// Resolve the session on cold start. Called from the splash screen.
  Future<void> restore() async {
    final repo = ref.read(authRepositoryProvider);
    if (!await repo.hasSession()) {
      state = const AuthState(status: AuthStatus.signedOut);
      return;
    }
    try {
      final user = await repo.fetchProfile();
      state = AuthState(status: AuthStatus.signedIn, user: user);
    } on Object catch (e) {
      // A stored token that the server rejects is not a crash — it is a
      // signed-out driver. Anything else (offline on launch) keeps the
      // session so the app can work from cache.
      debugPrint('AuthController.restore: $e');
      state = await repo.hasSession()
          ? AuthState(status: AuthStatus.signedIn, user: state.user)
          : const AuthState(status: AuthStatus.signedOut);
    }
  }

  Future<bool> requestOtp(String phoneNumber) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).requestOtp(phoneNumber);
      state = state.copyWith(isBusy: false, otpRequestedFor: phoneNumber);
      return true;
    } on Object catch (e) {
      state = state.copyWith(isBusy: false, error: e);
      return false;
    }
  }

  Future<bool> verifyOtp(String otp, {String? deviceToken}) async {
    final phone = state.otpRequestedFor;
    if (phone == null) {
      state = state.copyWith(error: Exception('Request an OTP first.'));
      return false;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).verifyOtp(
            phoneNumber: phone,
            otp: otp,
            deviceToken: deviceToken,
          );
      state = AuthState(status: AuthStatus.signedIn, user: user);
      return true;
    } on Object catch (e) {
      state = state.copyWith(isBusy: false, error: e);
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isBusy: true);
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
