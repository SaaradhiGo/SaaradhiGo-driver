import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import 'auth_state.dart';
import '../../domain/auth_repository.dart';
import '../../../../core/network/auth_session_events.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/user_model.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _repository;
  static const _rateLimitKey = 'otp_rate_limit_timestamps';
  static const _maxAttempts = 5;
  static const _timeWindow = Duration(minutes: 60);
  StreamSubscription<void>? _sessionExpirySub;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _sessionExpirySub?.cancel();
    _sessionExpirySub = AuthSessionEvents.sessionExpired.listen(
      (_) => sessionExpired(),
    );
    ref.onDispose(() {
      _sessionExpirySub?.cancel();
      _sessionExpirySub = null;
    });
    _checkAuthStatus();
    return const AuthUnknown();
  }

  /// Assigns [next] unless this provider has been disposed in the meantime.
  ///
  /// Every state write in this class happens after an await or a timer, and
  /// Riverpod 3 throws `Cannot use the Ref ... after it has been disposed` if
  /// the provider went away first. That is a real crash on a real phone --
  /// leave the login screen within the three seconds an error message is held
  /// and the delayed revert lands on a dead Ref -- and it is invisible to a
  /// test that never disposes its container.
  void _setState(AuthState next) {
    if (!ref.mounted) return;
    state = next;
  }

  /// Ends the session after the network layer reports an unrecoverable auth
  /// failure (refresh token rejected). The router redirects to /login.
  void sessionExpired() {
    if (state is AuthUnauthenticated) return;
    _setState(const AuthUnauthenticated(
      reason: 'Your session has expired. Please log in again.',
    ));
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final user = await SecureStorageService.getUser();
        _setState(AuthAuthenticated(user: user));
      } else {
        _setState(const AuthUnauthenticated());
      }
    } catch (e) {
      // Fail closed: an unreadable store is not a reason to assume a
      // session still exists.
      _setState(const AuthUnauthenticated());
    }
  }

  Future<bool> _checkRateLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampsJson = prefs.getString(_rateLimitKey) ?? '[]';
    final List<dynamic> timestampsRaw = jsonDecode(timestampsJson);
    final now = DateTime.now();

    // Filter out timestamps older than the time window
    final validTimestamps = timestampsRaw
        .map((ts) => DateTime.parse(ts as String))
        .where((ts) => now.difference(ts) <= _timeWindow)
        .toList();

    if (validTimestamps.length >= _maxAttempts) {
      return false; // Rate limit exceeded
    }

    // Add current attempt
    validTimestamps.add(now);
    await prefs.setString(
      _rateLimitKey,
      jsonEncode(validTimestamps.map((ts) => ts.toIso8601String()).toList()),
    );
    return true;
  }

  Future<void> requestOtp(String phoneNumber) async {
    final previousState = state;
    _setState(const AuthRequestingOtp());

    final canProceed = await _checkRateLimit();
    if (!canProceed) {
      _setState(const AuthError(
        message: 'Too many attempts. Please try again later.',
      ));
      // Revert to previous valid state after a short delay so UI can recover
      Future.delayed(const Duration(seconds: 3), () {
        _setState(previousState);
      });
      return;
    }

    try {
      await _repository.requestOtp(phoneNumber);
      _setState(AuthOtpSent(phoneNumber: phoneNumber));
    } on Failure catch (e) {
      _setState(AuthError(message: e.message));
      Future.delayed(const Duration(seconds: 3), () {
        _setState(previousState);
      });
    } catch (e) {
      _setState(AuthError(message: e.toString().replaceAll('Exception: ', '')));
      Future.delayed(const Duration(seconds: 3), () {
        _setState(previousState);
      });
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    final previousState = state;
    _setState(AuthVerifyingOtp(phoneNumber: phoneNumber));

    final canProceed = await _checkRateLimit();
    if (!canProceed) {
      _setState(const AuthError(
        message: 'Too many attempts. Please try again later.',
      ));
      Future.delayed(const Duration(seconds: 3), () {
        _setState(previousState);
      });
      return;
    }

    try {
      final user = await _repository.verifyOtp(phoneNumber, otp);
      _setState(AuthAuthenticated(user: user));
    } on Failure catch (e) {
      _setState(AuthError(message: e.message));
      Future.delayed(const Duration(seconds: 3), () {
        _setState(previousState);
      });
    } catch (e) {
      _setState(AuthError(message: e.toString().replaceAll('Exception: ', '')));
      Future.delayed(const Duration(seconds: 3), () {
        _setState(previousState);
      });
    }
  }

  /// Email + password sign-in.
  ///
  /// No client-side rate limit, deliberately. The OTP paths have one because
  /// every attempt costs an SMS; an email attempt costs nothing, the server
  /// enforces the lockout, and a client-side counter here would lock a driver
  /// out of their own login screen without being any obstacle to an attacker
  /// who is not using this app.
  Future<void> emailLogin({
    required String email,
    required String password,
  }) async {
    final previousState = state;
    _setState(const AuthSigningIn());

    try {
      final user = await _repository.emailLogin(
        email: email.trim(),
        password: password,
      );
      _setState(AuthAuthenticated(user: user));
    } on Failure catch (e) {
      // The server's own words -- "Invalid email or password." for both a
      // wrong password and an unknown address, so nothing here reveals which.
      _setState(AuthError(message: e.message));
      Future.delayed(const Duration(seconds: 3), () {
        _setState(previousState);
      });
    } catch (e) {
      _setState(AuthError(message: e.toString().replaceAll('Exception: ', '')));
      Future.delayed(const Duration(seconds: 3), () {
        _setState(previousState);
      });
    }
  }

  /// Asks for a password reset link. Returns the server's message, which is
  /// identical for a known and an unknown address by design.
  Future<String> requestPasswordReset(String email) =>
      _repository.requestPasswordReset(email.trim());

  /// Persists a mutation of the authenticated user (e.g. after a successful
  /// `PATCH /auth/update/`) into both the live auth state and secure storage so
  /// the change survives a restart without a fresh profile fetch.
  Future<void> updateUser(UserModel user) async {
    await SecureStorageService.saveUser(user);
    _setState(AuthAuthenticated(user: user));
  }

  /// Ends the session locally no matter what the stores do.
  ///
  /// The state change used to sit on the line AFTER `await
  /// _repository.logout()`, so a throw from secure storage skipped it and
  /// left the driver signed in on a screen they had just logged out of.
  /// Clearing the store is best-effort and cannot now throw either -- see
  /// SecureStorageService.clearTokens.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (e) {
      AppLogger.e('Clearing stored credentials failed during logout', e);
    } finally {
      _setState(const AuthUnauthenticated());
    }
  }
}
