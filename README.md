# SaaradhiGo Drive

The driver-side Flutter app for the VahanGo / SaaradhiGo ride-hailing
platform. Riders use [SaaradhiGo-mobile](../SaaradhiGo-mobile); ops use
[SaaradhiGo-web](../SaaradhiGo-web); both talk to
[SaaradhiGo-backend](../SaaradhiGo-backend).

This app **consumes the existing backend API**. It adds no endpoints. Every
path it calls is listed in [`lib/core/network/api_endpoints.dart`](lib/core/network/api_endpoints.dart)
and mirrors `servers/*/urls.py` on the backend.

## Running it

```bash
flutter pub get

# Dev
flutter run \
  --dart-define=API_BASE_URL=https://dev.api.saaradhigo.in/api/v1 \
  --dart-define=WS_BASE_URL=wss://dev.api.saaradhigo.in/ws

# Release APK (the Maps key is a Gradle property, never committed)
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.saaradhigo.in/api/v1 \
  --dart-define=WS_BASE_URL=wss://api.saaradhigo.in/ws \
  -Pmaps.apiKey=AIza...
```

Nothing secret lives in the repo or in an asset bundle. The rider app shipped
its Google Maps key inside `assets/.env`, which anyone who downloads the APK
can extract — this app takes configuration from `--dart-define` and the Maps
key from a Gradle property injected into the manifest at build time.

## Architecture

Feature-first, with a Clean Architecture split inside each feature:

```
lib/
  app/            MaterialApp, GoRouter, Material 3 theme
  core/
    config/       compile-time configuration
    network/      Dio client (auth + refresh + envelope), endpoints, errors
    ws/           reconnecting WebSocket + the channel abstraction it needs
    storage/      secure token store, non-secret local store
    location/     GPS acquisition and permission handling
    push/         Firebase Cloud Messaging
    widgets/      shared UI primitives
    providers.dart  the dependency graph
  features/
    <feature>/
      domain/       entities + repository interfaces (no Flutter, no Dio)
      data/         repository implementations against the real API
      presentation/ Riverpod controllers + screens
```

**Dependency rule:** `presentation → domain ← data`. A screen never imports
Dio or an endpoint constant; it depends on a repository interface from
`domain/`. That is what lets the widget and lifecycle tests run the real
controllers against fakes with no network.

### Why some things are where they are

- **Token refresh lives in `ApiClient`, not in a controller.** Access tokens
  last 15 minutes and a driver works 10-hour shifts, so refresh has to be
  invisible. Concurrent 401s collapse into one refresh, and the original
  request is replayed with the new token. A driver must never be bounced to a
  login screen with a rider in the car.

- **`WsClient` depends on a three-method `WsChannel`**, not on
  `package:web_socket_channel` directly. Dispatch arrives over this socket, so
  its reconnect / backoff / ping behaviour has to be testable frame by frame.

- **`DutyController` owns "am I working".** Going online is location
  permission + a GPS fix + the `/ws/driver/location/` socket — all three or
  none. A driver who believes they are online but is not is invisible to
  dispatch and has no way to tell.

- **`TripController` mirrors the server's state machine** rather than keeping
  its own. Every transition is a WS action the server validates; the app
  renders what comes back.

## Backend contract

| Flow | Transport |
|---|---|
| OTP login, profile, earnings, withdrawals, history, support | REST |
| Driver presence, location, incoming offers, `trip_taken` | `ws/driver/location/` |
| Trip lifecycle (accept → reached → start → complete, cash) | `ws/ride/trip/<id>/` |
| Driver cancellation | REST (`/driver-cancel/`) |
| SOS | REST (`/sos/`) |

Cancellation is REST and not a socket action on purpose: that endpoint is what
records the `DriverCancellation` row and applies the rolling cooldown.

## Testing

```bash
flutter analyze          # zero issues
flutter test             # unit + widget + API + WebSocket + lifecycle
flutter test integration_test/app_test.dart   # needs a device/emulator
```

- `test/api_client_test.dart` — envelope unwrapping, bearer attach, the
  401-refresh-replay path, error translation. Uses a fake `HttpClientAdapter`
  so the real interceptor chain is under test rather than stubbed.
- `test/ws_client_test.dart` — connect, decode, malformed frames, reconnect
  with backoff, intentional close.
- `test/trip_lifecycle_test.dart` — the whole trip state machine driven by the
  exact frames `TripStatusConsumer` emits, including losing an accept race and
  a rejected OTP.
- `test/domain_test.dart` — entity parsing and the gating rules.
- `test/widget_test.dart` — duty toggle states, profile/KYC rendering, error
  and empty states, cancel-sheet validation.

## Still to do before the pilot

- `google-services.json` for Firebase, then uncomment the plugin in
  `android/app/build.gradle.kts`. Push is the redundant dispatch channel; the
  app runs without it.
- A real upload keystore (release currently signs with the debug key).
- Telugu and Hindi localisation — the setting is persisted, the strings are
  not yet extracted.
- iOS `Info.plist` usage strings and background modes.
