import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/elite_status_model.dart';
import 'package:saaradhigo_driver/domain/models/incentive_quest_model.dart';
import 'package:saaradhigo_driver/features/incentives/domain/repositories/incentives_repository.dart';
import 'package:saaradhigo_driver/features/incentives/presentation/providers/incentives_providers.dart';

class _StubIncentivesRepository implements IncentivesRepository {
  bool shouldThrow = false;
  EliteStatusModel eliteStatusToReturn = const EliteStatusModel(
    tier: 'Gold',
    totalTrips: 120,
    rating: '4.85',
    acceptanceRate: '98%',
    cancellationRate: '1%',
    nextTier: 'Platinum',
    tripsToNextTier: 80,
  );

  @override
  Future<List<IncentiveQuestModel>> getIncentives() async {
    return [];
  }

  @override
  Future<EliteStatusModel> getEliteStatus() async {
    if (shouldThrow) throw Exception('API Failure');
    return eliteStatusToReturn;
  }
}

void main() {
  late ProviderContainer container;
  late _StubIncentivesRepository stubRepo;

  setUp(() {
    stubRepo = _StubIncentivesRepository();
    container = ProviderContainer(
      overrides: [incentivesRepositoryProvider.overrideWithValue(stubRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('EliteStatusNotifier', () {
    test('initial state has initial status and default model', () {
      final state = container.read(eliteStatusNotifierProvider);
      expect(state.status, equals(EliteStatusStatus.initial));
      expect(state.eliteStatus.tier, equals('Silver'));
    });

    test(
      'fetchEliteStatus transitions to success and populates metrics',
      () async {
        final notifier = container.read(eliteStatusNotifierProvider.notifier);
        await notifier.fetchEliteStatus();

        final state = container.read(eliteStatusNotifierProvider);
        expect(state.status, equals(EliteStatusStatus.success));
        expect(state.eliteStatus.tier, equals('Gold'));
        expect(state.eliteStatus.totalTrips, equals(120));
        expect(state.eliteStatus.rating, equals('4.85'));
        expect(state.eliteStatus.tierEnum, equals(EliteTier.gold));
        expect(state.eliteStatus.isRatingQualified, isTrue);
        expect(state.eliteStatus.isAcceptanceQualified, isTrue);
        expect(state.eliteStatus.isCancellationQualified, isTrue);
      },
    );

    test(
      'fetchEliteStatus transitions to error on repository failure',
      () async {
        stubRepo.shouldThrow = true;
        final notifier = container.read(eliteStatusNotifierProvider.notifier);
        await notifier.fetchEliteStatus();

        final state = container.read(eliteStatusNotifierProvider);
        expect(state.status, equals(EliteStatusStatus.error));
        expect(state.hasError, isTrue);
        expect(state.errorMessage, isNotNull);
      },
    );
  });
}
