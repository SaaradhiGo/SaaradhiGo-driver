import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/vehicle_model.dart';
import 'package:saaradhigo_driver/features/onboarding/data/models/vehicle_request_dto.dart';
import 'package:saaradhigo_driver/features/vehicle/domain/repositories/vehicles_repository.dart';
import 'package:saaradhigo_driver/features/vehicle/presentation/providers/vehicle_info_providers.dart';

class StubVehiclesRepository implements VehiclesRepository {
  bool shouldThrow = false;
  List<VehicleModel> vehiclesToReturn = [
    const VehicleModel(
      id: 101,
      vehicleNumber: 'TS07AB1234',
      vehicleType: 'sedan',
      brand: 'Maruti',
      model: 'Swift Dzire',
      color: 'White',
      year: 2022,
      capacity: 4,
      status: 'active',
    ),
    const VehicleModel(
      id: 102,
      vehicleNumber: 'TS08CD5678',
      vehicleType: 'suv',
      brand: 'Toyota',
      model: 'Innova',
      color: 'Silver',
      year: 2023,
      capacity: 6,
      status: 'inactive',
    ),
  ];

  int? lastSwitchedId;

  @override
  Future<List<VehicleModel>> getVehicles() async {
    if (shouldThrow) throw Exception('Network error');
    return vehiclesToReturn;
  }

  @override
  Future<void> switchActiveVehicle(int vehicleId) async {
    if (shouldThrow) throw Exception('Switch error');
    lastSwitchedId = vehicleId;
  }

  @override
  Future<VehicleModel> updateVehicle(
    int vehicleId,
    Map<String, dynamic> data,
  ) async {
    if (shouldThrow) throw Exception('Update error');
    return vehiclesToReturn.firstWhere((v) => v.id == vehicleId);
  }

  @override
  Future<VehicleModel> addVehicle(
    VehicleRequestDto dto, {
    dynamic onProgress,
  }) async {
    if (shouldThrow) throw Exception('Add error');
    final newVehicle = VehicleModel(
      id: 103,
      vehicleNumber: dto.registrationNumber,
      vehicleType: dto.vehicleType,
      brand: dto.make,
      model: dto.model,
    );
    vehiclesToReturn.add(newVehicle);
    return newVehicle;
  }
}

void main() {
  late StubVehiclesRepository stubRepo;
  late ProviderContainer container;

  setUp(() {
    stubRepo = StubVehiclesRepository();
    container = ProviderContainer(
      overrides: [vehiclesRepositoryProvider.overrideWithValue(stubRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial fetch loads active vehicle and fleet vehicles', () async {
    final notifier = container.read(vehicleInfoNotifierProvider.notifier);
    await notifier.fetchVehicleInfo();

    final state = container.read(vehicleInfoNotifierProvider);
    expect(state.status, VehicleInfoStatus.success);
    expect(state.activeVehicle, isNotNull);
    expect(state.activeVehicle?.vehicleNumber, 'TS07AB1234');
    expect(state.allVehicles.length, 2);
  });

  test(
    'switchActiveVehicle updates active vehicle and calls repository',
    () async {
      final notifier = container.read(vehicleInfoNotifierProvider.notifier);
      await notifier.fetchVehicleInfo();

      final success = await notifier.switchActiveVehicle(102);
      expect(success, isTrue);
      expect(stubRepo.lastSwitchedId, 102);

      final state = container.read(vehicleInfoNotifierProvider);
      expect(state.activeVehicle?.id, 102);
      expect(state.activeVehicle?.model, 'Innova');
    },
  );

  test('fetchVehicleInfo handles empty vehicle list', () async {
    stubRepo.vehiclesToReturn = [];
    final notifier = container.read(vehicleInfoNotifierProvider.notifier);
    await notifier.fetchVehicleInfo();

    final state = container.read(vehicleInfoNotifierProvider);
    expect(state.status, VehicleInfoStatus.empty);
    expect(state.activeVehicle, isNull);
    expect(state.allVehicles, isEmpty);
  });

  test('fetchVehicleInfo handles error', () async {
    stubRepo.shouldThrow = true;
    final notifier = container.read(vehicleInfoNotifierProvider.notifier);
    await notifier.fetchVehicleInfo();

    final state = container.read(vehicleInfoNotifierProvider);
    expect(state.status, VehicleInfoStatus.error);
    expect(state.errorMessage, isNotNull);
  });
}
