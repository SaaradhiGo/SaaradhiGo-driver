import '../../../../domain/models/elite_status_model.dart';
import '../../../../domain/models/incentive_quest_model.dart';

abstract class IncentivesRepository {
  Future<List<IncentiveQuestModel>> getIncentives();
  Future<EliteStatusModel> getEliteStatus();
}
