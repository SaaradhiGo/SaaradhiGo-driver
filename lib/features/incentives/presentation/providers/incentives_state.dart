import '../../../../domain/models/incentive_quest_model.dart';

enum IncentivesStatus { initial, loading, success, empty, error, refreshing }

class IncentivesState {
  final IncentivesStatus status;
  final List<IncentiveQuestModel> quests;
  final String? errorMessage;

  const IncentivesState({
    this.status = IncentivesStatus.initial,
    this.quests = const [],
    this.errorMessage,
  });

  bool get isLoading => status == IncentivesStatus.loading;
  bool get isRefreshing => status == IncentivesStatus.refreshing;
  bool get isEmpty =>
      status == IncentivesStatus.empty ||
      (status == IncentivesStatus.success && quests.isEmpty);
  bool get hasError => status == IncentivesStatus.error;

  List<IncentiveQuestModel> get activeQuests =>
      quests.where((q) => !q.isCompleted).toList();

  List<IncentiveQuestModel> get completedQuests =>
      quests.where((q) => q.isCompleted).toList();

  IncentiveQuestModel? get dailyGoalQuest {
    try {
      return quests.firstWhere((q) => q.questType == QuestType.dailyGoal);
    } catch (_) {
      return null;
    }
  }

  IncentiveQuestModel? get weeklyMilestoneQuest {
    try {
      return quests.firstWhere((q) => q.questType == QuestType.weeklyMilestone);
    } catch (_) {
      return null;
    }
  }

  double get totalWeeklyEarned {
    double total = 0.0;
    for (final q in completedQuests) {
      total += double.tryParse(q.rewardAmount) ?? 0.0;
    }
    return total;
  }

  IncentivesState copyWith({
    IncentivesStatus? status,
    List<IncentiveQuestModel>? quests,
    String? errorMessage,
  }) {
    return IncentivesState(
      status: status ?? this.status,
      quests: quests ?? this.quests,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
