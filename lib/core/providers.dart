import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/earnings/data/earnings_repository_impl.dart';
import '../features/earnings/domain/earnings_repository.dart';
import '../features/history/data/history_repository_impl.dart';
import '../features/history/domain/history_repository.dart';
import '../features/profile/data/profile_repository_impl.dart';
import '../features/profile/domain/profile_repository.dart';
import '../features/safety/data/safety_repository_impl.dart';
import '../features/safety/domain/safety_repository.dart';
import '../features/trip/data/trip_repository_impl.dart';
import '../features/trip/domain/trip_repository.dart';
import '../features/withdrawals/data/withdrawal_repository_impl.dart';
import '../features/withdrawals/domain/withdrawal_repository.dart';
import 'location/location_service.dart';
import 'network/api_client.dart';
import 'ws/ws_channel.dart';
import 'storage/local_store.dart';
import 'storage/token_store.dart';

/// Root of the dependency graph.
///
/// Everything below is constructed once and injected downward, so a test can
/// override any single node — the API client, the token store, a repository —
/// without the rest of the app noticing.

/// Overridden in `main()` once SharedPreferences has loaded, and in tests with
/// an in-memory instance. Reading it before that override is a programming
/// error, hence the throw rather than a silent default.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Bumped when the refresh token is finally spent and the driver has to sign
/// in again. The auth controller listens; the router reacts.
class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void signal() => state = state + 1;
}

final sessionExpiredProvider =
    NotifierProvider<SessionExpiredNotifier, int>(SessionExpiredNotifier.new);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.watch(tokenStoreProvider),
    onSessionExpired: () {
      // Signal rather than navigate: this callback can fire from any isolate
      // or mid-frame, and navigation must happen from the router's listener.
      ref.read(sessionExpiredProvider.notifier).signal();
    },
  );
});

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

/// How a WebSocket is opened. Overridden in tests with a fake channel so the
/// dispatch and trip flows can be driven frame by frame without a server.
final wsConnectorProvider = Provider<WsChannel Function(Uri)>(
  (ref) => RealWsChannel.connect,
);

// --- repositories ---------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
    ref.watch(localStoreProvider),
  ),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(apiClientProvider)),
);

final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => TripRepositoryImpl(ref.watch(apiClientProvider)),
);

final earningsRepositoryProvider = Provider<EarningsRepository>(
  (ref) => EarningsRepositoryImpl(ref.watch(apiClientProvider)),
);

final withdrawalRepositoryProvider = Provider<WithdrawalRepository>(
  (ref) => WithdrawalRepositoryImpl(ref.watch(apiClientProvider)),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepositoryImpl(ref.watch(apiClientProvider)),
);

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepositoryImpl(ref.watch(apiClientProvider)),
);
