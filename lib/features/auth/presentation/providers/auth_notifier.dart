import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import 'auth_state.dart';
import '../../domain/auth_repository.dart';
import '../../../../core/network/auth_session_events.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/failures.dart';
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

  /// Ends the session after the network layer reports an unrecoverable auth
  /// failure (refresh token rejected). The router redirects to /login.
  void sessionExpired() {
    if (state is AuthUnauthenticated) return;
    state = const AuthUnauthenticated(
      reason: 'Your session has expired. Please log in again.',
    );
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final user = await SecureStorageService.getUser();
        state = AuthAuthenticated(user: user);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      // Fallback if secure storage throws an error (e.g., on some Web environments)
      state = const AuthUnauthenticated();
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
    state = const AuthRequestingOtp();

    final canProceed = await _checkRateLimit();
    if (!canProceed) {
      state = const AuthError(
        message: 'Too many attempts. Please try again later.',
      );
      // Revert to previous valid state after a short delay so UI can recover
      Future.delayed(const Duration(seconds: 3), () {
        state = previousState;
      });
      return;
    }

    try {
      await _repository.requestOtp(phoneNumber);
      state = AuthOtpSent(phoneNumber: phoneNumber);
    } on Failure catch (e) {
      state = AuthError(message: e.message);
      Future.delayed(const Duration(seconds: 3), () {
        state = previousState;
      });
    } catch (e) {
      state = AuthError(message: e.toString().replaceAll('Exception: ', ''));
      Future.delayed(const Duration(seconds: 3), () {
        state = previousState;
      });
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    final previousState = state;
    state = AuthVerifyingOtp(phoneNumber: phoneNumber);

    final canProceed = await _checkRateLimit();
    if (!canProceed) {
      state = const AuthError(
        message: 'Too many attempts. Please try again later.',
      );
      Future.delayed(const Duration(seconds: 3), () {
        state = previousState;
      });
      return;
    }

    try {
      final user = await _repository.verifyOtp(phoneNumber, otp);
      state = AuthAuthenticated(user: user);
    } on Failure catch (e) {
      state = AuthError(message: e.message);
      Future.delayed(const Duration(seconds: 3), () {
        state = previousState;
      });
    } catch (e) {
      state = AuthError(message: e.toString().replaceAll('Exception: ', ''));
      Future.delayed(const Duration(seconds: 3), () {
        state = previousState;
      });
    }
  }

  /// Persists a mutation of the authenticated user (e.g. after a successful
  /// `PATCH /auth/update/`) into both the live auth state and secure storage so
  /// the change survives a restart without a fresh profile fetch.
  Future<void> updateUser(UserModel user) async {
    await SecureStorageService.saveUser(user);
    state = AuthAuthenticated(user: user);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }
}
