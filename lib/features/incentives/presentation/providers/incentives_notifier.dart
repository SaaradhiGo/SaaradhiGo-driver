import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/incentives_repository.dart';
import 'incentives_providers.dart';

class IncentivesNotifier extends Notifier<IncentivesState> {
  late IncentivesRepository _repository;

  @override
  IncentivesState build() {
    try {
      _repository = ref.watch(incentivesRepositoryProvider);
    } catch (_) {
      // Test environment fallback
    }
    return const IncentivesState();
  }

  Future<void> fetchIncentives({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    if (refresh) {
      state = state.copyWith(status: IncentivesStatus.refreshing);
    } else {
      state = state.copyWith(status: IncentivesStatus.loading);
    }

    try {
      final quests = await _repository.getIncentives();
      state = state.copyWith(
        status: quests.isEmpty
            ? IncentivesStatus.empty
            : IncentivesStatus.success,
        quests: quests,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: IncentivesStatus.error,
        errorMessage: 'Unable to load incentives. Please try again.',
      );
    }
  }
}
