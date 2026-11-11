import 'dart:async';

/// Broadcasts terminal authentication-failure signals raised by the network
/// layer so the auth layer can end the session and route the driver to login.
///
/// Events are terminal by definition: the refresh token was rejected or is
/// gone, so the session cannot be recovered. Transient failures such as
/// network errors while refreshing never emit here.
class AuthSessionEvents {
  AuthSessionEvents._();

  static final StreamController<void> _sessionExpired =
      StreamController<void>.broadcast();

  static Stream<void> get sessionExpired => _sessionExpired.stream;

  static void emitSessionExpired() {
    _sessionExpired.add(null);
  }
}
