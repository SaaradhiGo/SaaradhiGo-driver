import '../../../../domain/models/vehicle_model.dart';

enum VehicleInfoStatus { initial, loading, success, empty, error, refreshing }

class VehicleInfoState {
  final VehicleInfoStatus status;
  final VehicleModel? activeVehicle;
  final List<VehicleModel> allVehicles;
  final bool isSwitching;
  final String? errorMessage;

  const VehicleInfoState({
    this.status = VehicleInfoStatus.initial,
    this.activeVehicle,
    this.allVehicles = const [],
    this.isSwitching = false,
    this.errorMessage,
  });

  bool get isLoading => status == VehicleInfoStatus.loading;
  bool get isRefreshing => status == VehicleInfoStatus.refreshing;
  bool get isEmpty => status == VehicleInfoStatus.empty;
  bool get hasError => status == VehicleInfoStatus.error;

  VehicleInfoState copyWith({
    VehicleInfoStatus? status,
    VehicleModel? activeVehicle,
    List<VehicleModel>? allVehicles,
    bool? isSwitching,
    String? errorMessage,
  }) {
    return VehicleInfoState(
      status: status ?? this.status,
      activeVehicle: activeVehicle ?? this.activeVehicle,
      allVehicles: allVehicles ?? this.allVehicles,
      isSwitching: isSwitching ?? this.isSwitching,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
