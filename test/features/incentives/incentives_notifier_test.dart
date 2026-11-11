import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/elite_status_model.dart';
import 'package:saaradhigo_driver/domain/models/incentive_quest_model.dart';
import 'package:saaradhigo_driver/features/incentives/domain/repositories/incentives_repository.dart';
import 'package:saaradhigo_driver/features/incentives/presentation/providers/incentives_providers.dart';

class _StubIncentivesRepository implements IncentivesRepository {
  bool shouldThrow = false;
  List<IncentiveQuestModel> questsToReturn = [
    const IncentiveQuestModel(
      id: 1,
      title: 'Daily Goal',
      targetTrips: 20,
      progressTrips: 12,
      rewardAmount: '300.00',
      isCompleted: false,
      type: 'daily_goal',
    ),
    const IncentiveQuestModel(
      id: 2,
      title: 'Weekly Milestone',
      targetTrips: 50,
      progressTrips: 50,
      rewardAmount: '1000.00',
      isCompleted: true,
      type: 'weekly_milestone',
    ),
  ];

  @override
  Future<List<IncentiveQuestModel>> getIncentives() async {
    if (shouldThrow) throw Exception('Network Failure');
    return questsToReturn;
  }

  @override
  Future<EliteStatusModel> getEliteStatus() async {
    if (shouldThrow) throw Exception('Network Failure');
    return const EliteStatusModel(tier: 'Gold');
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

  group('IncentivesNotifier', () {
    test('initial state has empty quests and initial status', () {
      final state = container.read(incentivesNotifierProvider);
      expect(state.status, equals(IncentivesStatus.initial));
      expect(state.quests, isEmpty);
      expect(state.activeQuests, isEmpty);
      expect(state.completedQuests, isEmpty);
    });

    test(
      'fetchIncentives transitions to success and separates active and completed quests',
      () async {
        final notifier = container.read(incentivesNotifierProvider.notifier);
        await notifier.fetchIncentives();

        final state = container.read(incentivesNotifierProvider);
        expect(state.status, equals(IncentivesStatus.success));
        expect(state.quests.length, equals(2));
        expect(state.activeQuests.length, equals(1));
        expect(state.activeQuests.first.title, equals('Daily Goal'));
        expect(state.completedQuests.length, equals(1));
        expect(state.completedQuests.first.title, equals('Weekly Milestone'));
        expect(state.totalWeeklyEarned, equals(1000.00));
        expect(state.dailyGoalQuest, isNotNull);
        expect(state.weeklyMilestoneQuest, isNotNull);
      },
    );

    test('fetchIncentives transitions to empty when no quests exist', () async {
      stubRepo.questsToReturn = [];
      final notifier = container.read(incentivesNotifierProvider.notifier);
      await notifier.fetchIncentives();

      final state = container.read(incentivesNotifierProvider);
      expect(state.status, equals(IncentivesStatus.empty));
      expect(state.isEmpty, isTrue);
    });

    test(
      'fetchIncentives transitions to error on repository failure',
      () async {
        stubRepo.shouldThrow = true;
        final notifier = container.read(incentivesNotifierProvider.notifier);
        await notifier.fetchIncentives();

        final state = container.read(incentivesNotifierProvider);
        expect(state.status, equals(IncentivesStatus.error));
        expect(state.hasError, isTrue);
        expect(state.errorMessage, isNotNull);
      },
    );
  });
}
