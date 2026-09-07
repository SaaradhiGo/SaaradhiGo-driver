import '../../../../domain/models/elite_status_model.dart';
import '../../../../domain/models/incentive_quest_model.dart';
import '../../domain/repositories/incentives_repository.dart';
import '../data_sources/incentives_remote_data_source.dart';

class IncentivesRepositoryImpl implements IncentivesRepository {
  final IncentivesRemoteDataSource remoteDataSource;

  IncentivesRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<IncentiveQuestModel>> getIncentives() {
    return remoteDataSource.getIncentives();
  }

  @override
  Future<EliteStatusModel> getEliteStatus() {
    return remoteDataSource.getEliteStatus();
  }
}
