import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_type_converters.dart';

part 'incentive_quest_model.freezed.dart';
part 'incentive_quest_model.g.dart';

enum QuestType {
  dailyGoal,
  weeklyMilestone,
  peakHour,
  marathon,
  streak,
  custom;

  static QuestType fromString(String? type, String? title) {
    final t = '${type ?? ''} ${title ?? ''}'.toLowerCase();
    if (t.contains('daily') || t.contains('day')) return QuestType.dailyGoal;
    if (t.contains('weekly') || t.contains('week')) {
      return QuestType.weeklyMilestone;
    }
    if (t.contains('peak') || t.contains('rush') || t.contains('boost')) {
      return QuestType.peakHour;
    }
    if (t.contains('marathon') || t.contains('mileage')) {
      return QuestType.marathon;
    }
    if (t.contains('streak')) return QuestType.streak;
    return QuestType.custom;
  }
}

@freezed
abstract class IncentiveQuestModel with _$IncentiveQuestModel {
  const IncentiveQuestModel._();

  const factory IncentiveQuestModel({
    @JsonKey(fromJson: intFromJson) required int id,
    @Default('') String title,
    @Default('') String description,
    @JsonKey(name: 'target_trips', fromJson: intFromJson)
    @Default(1)
    int targetTrips,
    @JsonKey(name: 'progress_trips', fromJson: intFromJson)
    @Default(0)
    int progressTrips,
    @JsonKey(name: 'reward_amount', fromJson: moneyFromJson)
    @Default('0.00')
    String rewardAmount,
    @JsonKey(name: 'is_completed', fromJson: boolFromJson)
    @Default(false)
    bool isCompleted,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    String? type,
  }) = _IncentiveQuestModel;

  factory IncentiveQuestModel.fromJson(Map<String, dynamic> json) =>
      _$IncentiveQuestModelFromJson(json);

  double get progressFraction {
    if (targetTrips <= 0) return isCompleted ? 1.0 : 0.0;
    return (progressTrips / targetTrips).clamp(0.0, 1.0);
  }

  int get remainingTrips {
    final diff = targetTrips - progressTrips;
    return diff > 0 ? diff : 0;
  }

  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final remaining = expiresAt!.difference(DateTime.now());
    return !remaining.isNegative && remaining.inHours < 6;
  }

  QuestType get questType => QuestType.fromString(type, title);

  String get formattedExpiry {
    if (expiresAt == null) return '';
    final remaining = expiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inDays >= 1) {
      return 'Ends in ${remaining.inDays}d';
    }
    if (remaining.inHours >= 1) {
      return 'Ends in ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
    }
    return 'Ends in ${remaining.inMinutes}m';
  }
}
