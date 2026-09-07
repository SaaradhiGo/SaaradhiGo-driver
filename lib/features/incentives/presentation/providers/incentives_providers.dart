import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/incentives_remote_data_source.dart';
import '../../data/repositories/incentives_repository_impl.dart';
import '../../domain/repositories/incentives_repository.dart';
import 'elite_status_notifier.dart';
import 'elite_status_state.dart';
import 'incentives_notifier.dart';
import 'incentives_state.dart';

export 'elite_status_notifier.dart';
export 'elite_status_state.dart';
export 'incentives_notifier.dart';
export 'incentives_state.dart';

final incentivesRemoteDataSourceProvider = Provider<IncentivesRemoteDataSource>(
  (ref) {
    return IncentivesRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
  },
);

final incentivesRepositoryProvider = Provider<IncentivesRepository>((ref) {
  return IncentivesRepositoryImpl(
    ref.watch(incentivesRemoteDataSourceProvider),
  );
});

final incentivesNotifierProvider =
    NotifierProvider<IncentivesNotifier, IncentivesState>(() {
      return IncentivesNotifier();
    });

final eliteStatusNotifierProvider =
    NotifierProvider<EliteStatusNotifier, EliteStatusState>(() {
      return EliteStatusNotifier();
    });
