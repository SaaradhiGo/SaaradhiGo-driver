import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/ws/ws_client.dart';
import '../../dispatch/domain/ride_offer.dart';

enum DutyStatus {
  /// Not working. No socket, no GPS, not dispatchable.
  offline,

  /// Permissions granted, socket opening.
  goingOnline,

  /// Live: heartbeat flowing, eligible for offers.
  online,

  /// Socket dropped while on duty. The driver is still *trying* to work, so
  /// we keep GPS running and let [WsClient] back off and retry.
  reconnecting,
}

@immutable
class DutyState {
  const DutyState({
    this.status = DutyStatus.offline,
    this.lastPosition,
    this.lastHeartbeatAt,
    this.error,
    this.denial,
  });

  final DutyStatus status;
  final Position? lastPosition;
  final DateTime? lastHeartbeatAt;
  final Object? error;

  /// Set when we could not go online because of permissions, so the UI can
  /// show the exact fix (turn on GPS / open settings) instead of a generic
  /// failure.
  final LocationDenial? denial;

  bool get isOnline => status == DutyStatus.online;
  bool get isBusy => status == DutyStatus.goingOnline;
  bool get isDispatchable => status == DutyStatus.online;

  /// True when the server has probably stopped considering us present: the
  /// heartbeat TTL is 45s server-side.
  bool get heartbeatStale {
    final last = lastHeartbeatAt;
    if (last == null) return false;
    return DateTime.now().difference(last) > const Duration(seconds: 45);
  }

  DutyState copyWith({
    DutyStatus? status,
    Position? lastPosition,
    DateTime? lastHeartbeatAt,
    Object? error,
    LocationDenial? denial,
    bool clearError = false,
  }) =>
      DutyState(
        status: status ?? this.status,
        lastPosition: lastPosition ?? this.lastPosition,
        lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
        error: clearError ? null : (error ?? this.error),
        denial: clearError ? null : (denial ?? this.denial),
      );
}

/// Owns "am I working right now".
///
/// Going online is three things that must all succeed together: location
/// permission, a GPS fix, and the `/ws/driver/location/` socket — the server
/// requires an opening lat/lng on that URL and marks the driver online on
/// connect. If any of them fails we go back to offline rather than leaving
/// the driver believing they are dispatchable when they are not.
class DutyController extends Notifier<DutyState> {
  WsClient? _socket;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<Map<String, dynamic>>? _eventSub;
  StreamSubscription<WsStatus>? _statusSub;
  Timer? _heartbeat;

  /// Offers arriving from dispatch. The dispatch controller listens here
  /// rather than owning a second socket.
  final _offers = StreamController<RideOffer>.broadcast();
  Stream<RideOffer> get offers => _offers.stream;

  /// `trip_taken` — another driver won an offer we are showing.
  final _taken = StreamController<int>.broadcast();
  Stream<int> get tripTaken => _taken.stream;

  @override
  DutyState build() {
    ref.onDispose(() {
      _heartbeat?.cancel();
      _positionSub?.cancel();
      _eventSub?.cancel();
      _statusSub?.cancel();
      _socket?.dispose();
      _offers.close();
      _taken.close();
    });
    return const DutyState();
  }

  LocationService get _location => ref.read(locationServiceProvider);

  Future<void> goOnline() async {
    if (state.status == DutyStatus.online ||
        state.status == DutyStatus.goingOnline) {
      return;
    }
    state = state.copyWith(status: DutyStatus.goingOnline, clearError: true);

    try {
      await _location.ensurePermissions();
      final position = await _location.currentPosition();
      state = state.copyWith(lastPosition: position);

      await _openSocket(position);
      await _location.start();

      _positionSub?.cancel();
      _positionSub = _location.positions.listen(_onPosition);

      // Belt and braces: a stationary driver produces no position events, so
      // without this timer the server's 45s heartbeat TTL would expire and
      // the sweeper would evict a driver who is simply parked at a taxi rank.
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(AppConfig.locationInterval, (_) {
        final last = _location.lastKnown ?? state.lastPosition;
        if (last != null) _pushLocation(last);
      });

      await ref.read(localStoreProvider).setWasOnDuty(true);
      state = state.copyWith(status: DutyStatus.online, clearError: true);
    } on LocationFailure catch (e) {
      state = DutyState(status: DutyStatus.offline, error: e, denial: e.denial);
    } on Object catch (e) {
      await _teardown();
      state = DutyState(status: DutyStatus.offline, error: e);
    }
  }

  Future<void> goOffline() async {
    await _teardown();
    await ref.read(localStoreProvider).setWasOnDuty(false);
    state = const DutyState();
  }

  /// Re-establish duty after a cold start when the driver was working when
  /// the app died. Silent by design: no permission dialogs, no error surface
  /// — if it cannot be restored the driver simply sees the offline toggle.
  Future<void> restoreIfWasOnDuty() async {
    if (!ref.read(localStoreProvider).wasOnDuty) return;
    try {
      await goOnline();
    } on Object catch (e) {
      debugPrint('DutyController.restore: $e');
    }
  }

  Future<void> _openSocket(Position position) async {
    await _socket?.dispose();

    final tokenStore = ref.read(tokenStoreProvider);
    final socket = WsClient(
      connector: ref.read(wsConnectorProvider),
      tokenProvider: tokenStore.readAccess,
      path: () async {
        // A fresh token AND fresh coordinates on every (re)connect: the
        // server reads both off the query string at accept time, so a stale
        // lat/lng would re-register the driver at a position they left
        // twenty minutes ago.
        final token = await tokenStore.readAccess() ?? '';
        final last = _location.lastKnown ?? position;
        return ApiEndpoints.driverLocationSocket(
          token: token,
          lat: last.latitude,
          lng: last.longitude,
        );
      },
    );
    _socket = socket;

    _eventSub = socket.events.listen(_onEvent);
    _statusSub = socket.status.listen((ws) {
      if (state.status == DutyStatus.offline) return;
      switch (ws) {
        case WsStatus.connected:
          state = state.copyWith(status: DutyStatus.online, clearError: true);
        case WsStatus.reconnecting:
        case WsStatus.connecting:
          state = state.copyWith(status: DutyStatus.reconnecting);
        case WsStatus.closed:
        case WsStatus.idle:
          break;
      }
    });

    await socket.connect();
  }

  void _onPosition(Position position) {
    state = state.copyWith(lastPosition: position);
    _pushLocation(position);
  }

  void _pushLocation(Position position) {
    final socket = _socket;
    if (socket == null || !socket.isConnected) return;
    socket.send({'lat': position.latitude, 'lng': position.longitude});
  }

  void _onEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'location_updated':
        // The server confirms it stored the frame. This — not the local send
        // — is what proves we are still in the geo index.
        state = state.copyWith(lastHeartbeatAt: DateTime.now());
      case 'ride_request':
        final offer = RideOffer.fromEvent(event);
        if (offer.tripId > 0 && !_offers.isClosed) _offers.add(offer);
      case 'trip_taken':
        final id = event['trip_id'];
        final tripId = id is num ? id.toInt() : int.tryParse('$id') ?? 0;
        if (tripId > 0 && !_taken.isClosed) _taken.add(tripId);
      case 'connection_established':
        state = state.copyWith(
          status: DutyStatus.online,
          lastHeartbeatAt: DateTime.now(),
          clearError: true,
        );
      case 'error':
        // The server refuses to bring a driver online during a fatigue or
        // cancellation lockout. Surface it and stand down — retrying would
        // just loop against the same rejection.
        final message = event['message']?.toString() ?? 'Dispatch error';
        state = state.copyWith(error: Exception(message));
    }
  }

  Future<void> _teardown() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _positionSub?.cancel();
    _positionSub = null;
    await _eventSub?.cancel();
    _eventSub = null;
    await _statusSub?.cancel();
    _statusSub = null;
    await _socket?.dispose();
    _socket = null;
    await _location.stop();
  }
}

final dutyControllerProvider =
    NotifierProvider<DutyController, DutyState>(DutyController.new);
