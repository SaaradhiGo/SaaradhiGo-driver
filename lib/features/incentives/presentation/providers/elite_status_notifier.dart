import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/incentives_repository.dart';
import 'incentives_providers.dart';

class EliteStatusNotifier extends Notifier<EliteStatusState> {
  late IncentivesRepository _repository;

  @override
  EliteStatusState build() {
    try {
      _repository = ref.watch(incentivesRepositoryProvider);
    } catch (_) {
      // Test environment fallback
    }
    return const EliteStatusState();
  }

  Future<void> fetchEliteStatus({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    if (refresh) {
      state = state.copyWith(status: EliteStatusStatus.refreshing);
    } else {
      state = state.copyWith(status: EliteStatusStatus.loading);
    }

    try {
      final eliteStatus = await _repository.getEliteStatus();
      state = state.copyWith(
        status: EliteStatusStatus.success,
        eliteStatus: eliteStatus,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: EliteStatusStatus.error,
        errorMessage: 'Unable to load Elite status. Please try again.',
      );
    }
  }
}
