import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/earnings_remote_data_source.dart';
import '../../data/repositories/earnings_repository_impl.dart';
import '../../domain/repositories/earnings_repository.dart';
import 'earnings_notifier.dart';
import 'earnings_state.dart';

export 'earnings_state.dart';

final earningsRemoteDataSourceProvider = Provider<EarningsRemoteDataSource>((
  ref,
) {
  return EarningsRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
});

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepositoryImpl(ref.watch(earningsRemoteDataSourceProvider));
});

final earningsNotifierProvider =
    NotifierProvider<EarningsNotifier, EarningsState>(() {
      return EarningsNotifier();
    });
