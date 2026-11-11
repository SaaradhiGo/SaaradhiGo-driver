import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/vehicle_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/repositories/vehicles_repository.dart';
import 'vehicle_info_providers.dart';

class VehicleInfoNotifier extends Notifier<VehicleInfoState> {
  late VehiclesRepository _repository;

  @override
  VehicleInfoState build() {
    try {
      _repository = ref.watch(vehiclesRepositoryProvider);
    } catch (_) {
      // Test environment fallback
    }
    return const VehicleInfoState();
  }

  Future<void> fetchVehicleInfo({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(status: VehicleInfoStatus.refreshing);
    } else {
      state = state.copyWith(status: VehicleInfoStatus.loading);
    }

    try {
      final vehicles = await _repository.getVehicles();

      // Attempt to get active vehicle from driver profile
      VehicleModel? active;
      try {
        final profileState = ref.read(driverProfileNotifierProvider);
        if (profileState is ProfileStateLoaded) {
          final profile = profileState.profile;
          if (profile.activeVehicleDetails != null) {
            active = VehicleModel.fromJson(profile.activeVehicleDetails!);
          } else if (profile.activeVehicle != null) {
            active = vehicles.cast<VehicleModel?>().firstWhere(
              (v) => v?.id == profile.activeVehicle,
              orElse: () => null,
            );
          }
        }
      } catch (_) {
        // Fallback to vehicles list if profile provider is unavailable
      }

      // If active vehicle is still null, take the first vehicle or vehicle with status == 'active'
      active ??= vehicles.cast<VehicleModel?>().firstWhere(
        (v) => v?.status?.toLowerCase() == 'active',
        orElse: () => vehicles.isNotEmpty ? vehicles.first : null,
      );

      if (active == null && vehicles.isEmpty) {
        state = state.copyWith(
          status: VehicleInfoStatus.empty,
          activeVehicle: null,
          allVehicles: [],
        );
      } else {
        state = state.copyWith(
          status: VehicleInfoStatus.success,
          activeVehicle: active,
          allVehicles: vehicles,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: VehicleInfoStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> switchActiveVehicle(int vehicleId) async {
    state = state.copyWith(isSwitching: true);
    try {
      await _repository.switchActiveVehicle(vehicleId);
      try {
        // Refresh global driver profile if available
        await ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
      } catch (_) {}

      final newActive = state.allVehicles.cast<VehicleModel?>().firstWhere(
        (v) => v?.id == vehicleId,
        orElse: () => null,
      );

      state = state.copyWith(
        activeVehicle: newActive ?? state.activeVehicle,
        isSwitching: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSwitching: false, errorMessage: e.toString());
      return false;
    }
  }
}
