import '../../../../domain/models/elite_status_model.dart';

enum EliteStatusStatus { initial, loading, success, error, refreshing }

class EliteStatusState {
  final EliteStatusStatus status;
  final EliteStatusModel eliteStatus;
  final String? errorMessage;

  const EliteStatusState({
    this.status = EliteStatusStatus.initial,
    this.eliteStatus = const EliteStatusModel(),
    this.errorMessage,
  });

  bool get isLoading => status == EliteStatusStatus.loading;
  bool get isRefreshing => status == EliteStatusStatus.refreshing;
  bool get hasError => status == EliteStatusStatus.error;

  EliteStatusState copyWith({
    EliteStatusStatus? status,
    EliteStatusModel? eliteStatus,
    String? errorMessage,
  }) {
    return EliteStatusState(
      status: status ?? this.status,
      eliteStatus: eliteStatus ?? this.eliteStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
