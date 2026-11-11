import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device currently reports any usable network transport.
///
/// Only a coarse transport signal — it does not prove the backend is reachable.
/// Used to render the Offline state and to short-circuit "go online" with a
/// useful message rather than letting the socket fail silently.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  yield _hasConnection(await connectivity.checkConnectivity());

  yield* connectivity.onConnectivityChanged.map(_hasConnection);
});

bool _hasConnection(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
}

/// Optimistic view of [connectivityProvider]: assumes connected until the
/// platform says otherwise, so a slow first probe never blocks the UI.
final isOnlineNetworkProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true;
});
