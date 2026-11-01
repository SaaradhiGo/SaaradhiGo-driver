import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/models/promo_incentive_model.dart';

/// `GET /api/v1/promotions/driver/incentives/`: the live incentives (module
/// 12) with this driver's progress. Separate from the older quests endpoint
/// (`/driver/driver/incentives/`), which the incentives screen still reads.
class PromoIncentivesService {
  PromoIncentivesService(this.dio);
  final Dio dio;

  Future<List<PromoIncentive>> fetch() async {
    final response = await dio.get(ApiEndpoints.promotionsDriverIncentives);
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    return PromoIncentive.listFromData(data);
  }
}

enum PromoIncentivesStatus { initial, loading, loaded, error }

class PromoIncentivesState {
  const PromoIncentivesState({
    this.status = PromoIncentivesStatus.initial,
    this.items = const [],
  });

  final PromoIncentivesStatus status;
  final List<PromoIncentive> items;

  bool get loaded => status == PromoIncentivesStatus.loaded;
  bool get failed => status == PromoIncentivesStatus.error;
  bool get isLoading => status == PromoIncentivesStatus.loading;

  /// Incentives in progress right now.
  List<PromoIncentive> activeAt(DateTime now) =>
      items.where((i) => i.isActiveAt(now)).toList();
}

final promoIncentivesServiceProvider = Provider<PromoIncentivesService>((ref) {
  return PromoIncentivesService(ref.watch(dioClientProvider).dio);
});

class PromoIncentivesNotifier extends Notifier<PromoIncentivesState> {
  @override
  PromoIncentivesState build() => const PromoIncentivesState();

  /// Never throws: a failure is a state, and the earnings card then keeps its
  /// old wording.
  Future<void> fetch() async {
    if (state.isLoading) return;
    // Keep what is on screen while a refresh runs.
    state = PromoIncentivesState(
      status: PromoIncentivesStatus.loading,
      items: state.items,
    );
    try {
      final items = await ref.read(promoIncentivesServiceProvider).fetch();
      state = PromoIncentivesState(
        status: PromoIncentivesStatus.loaded,
        items: items,
      );
    } catch (_) {
      state = PromoIncentivesState(
        status: PromoIncentivesStatus.error,
        items: state.items,
      );
    }
  }
}

final promoIncentivesProvider =
    NotifierProvider<PromoIncentivesNotifier, PromoIncentivesState>(
      PromoIncentivesNotifier.new,
    );

/// The line under "Incentives & Quests" on the earnings screen, or null to keep
/// the card's standing wording (nothing loaded yet, or the request failed, so
/// the card looks exactly as it did before).
///
/// Loaded and nothing in progress: the empty state. Otherwise the first active
/// incentive's progress, and how many more there are.
String? incentivesCardSummary(PromoIncentivesState state, DateTime now) {
  if (!state.loaded) return null;
  final active = state.activeAt(now);
  if (active.isEmpty) return 'No active incentives right now';
  final first = active.first;
  final more = active.length - 1;
  final text = '${first.name}: ${first.progressText}';
  return more > 0 ? '$text · +$more more' : text;
}
