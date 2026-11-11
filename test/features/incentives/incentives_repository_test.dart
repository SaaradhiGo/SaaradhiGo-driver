import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/elite_status_model.dart';
import 'package:saaradhigo_driver/domain/models/incentive_quest_model.dart';
import 'package:saaradhigo_driver/features/incentives/data/data_sources/incentives_remote_data_source.dart';
import 'package:saaradhigo_driver/features/incentives/data/repositories/incentives_repository_impl.dart';

class _FakeIncentivesRemoteDataSource implements IncentivesRemoteDataSource {
  List<IncentiveQuestModel> fakeQuests = [];
  EliteStatusModel fakeEliteStatus = const EliteStatusModel();

  @override
  Future<List<IncentiveQuestModel>> getIncentives() async {
    return fakeQuests;
  }

  @override
  Future<EliteStatusModel> getEliteStatus() async {
    return fakeEliteStatus;
  }
}

void main() {
  late _FakeIncentivesRemoteDataSource fakeDataSource;
  late IncentivesRepositoryImpl repository;

  setUp(() {
    fakeDataSource = _FakeIncentivesRemoteDataSource();
    repository = IncentivesRepositoryImpl(fakeDataSource);
  });

  group('IncentivesRepositoryImpl', () {
    test('getIncentives delegates to remoteDataSource', () async {
      fakeDataSource.fakeQuests = [
        const IncentiveQuestModel(
          id: 1,
          title: 'Daily Goal',
          targetTrips: 20,
          progressTrips: 12,
          rewardAmount: '300.00',
        ),
      ];

      final result = await repository.getIncentives();
      expect(result.length, equals(1));
      expect(result.first.title, equals('Daily Goal'));
      expect(result.first.progressTrips, equals(12));
    });

    test('getEliteStatus delegates to remoteDataSource', () async {
      fakeDataSource.fakeEliteStatus = const EliteStatusModel(
        tier: 'Platinum',
        totalTrips: 250,
        rating: '4.95',
      );

      final result = await repository.getEliteStatus();
      expect(result.tier, equals('Platinum'));
      expect(result.totalTrips, equals(250));
      expect(result.rating, equals('4.95'));
    });
  });
}
