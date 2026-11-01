import 'dart:convert';

/// When a JWT stops being accepted, read from the token itself.
///
/// The WebSocket handshake carries the access token as a query parameter and
/// never passes through Dio, so `AuthInterceptor`'s 401-driven refresh cannot
/// see it: the server simply refuses the upgrade and the client is told only
/// `WebSocketChannelException`. There is no status code to react to, so the
/// expiry has to be known before connecting rather than discovered afterwards.
///
/// Returns null when [token] is not a JWT, carries no `exp`, or cannot be
/// decoded. Callers treat null as "cannot tell" and use the token as-is --
/// refusing to connect over an unreadable token would be worse than letting
/// the server decide.
DateTime? jwtExpiry(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final payload = parts[1];
    // base64url without padding is what JWT uses; Dart's decoder wants it.
    final normalised = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalised));
    final claims = jsonDecode(decoded);
    if (claims is! Map) return null;

    final exp = claims['exp'];
    if (exp is! int) return null;

    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  } catch (_) {
    return null;
  }
}

/// True when [token] is expired, or close enough that it would very likely
/// expire mid-handshake.
///
/// [margin] exists because the alternative to refreshing slightly early is a
/// driver who goes offline for a round trip and a backoff cycle.
bool isJwtExpired(
  String token, {
  Duration margin = const Duration(seconds: 30),
  DateTime? now,
}) {
  final expiry = jwtExpiry(token);
  if (expiry == null) return false;
  final reference = (now ?? DateTime.now().toUtc()).toUtc();
  return !expiry.isAfter(reference.add(margin));
}
