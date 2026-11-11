import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/vehicle_model.dart';
import 'package:saaradhigo_driver/features/onboarding/data/models/vehicle_request_dto.dart';
import 'package:saaradhigo_driver/features/vehicle/domain/repositories/vehicles_repository.dart';
import 'package:saaradhigo_driver/features/vehicle/presentation/providers/vehicle_info_providers.dart';
import 'package:saaradhigo_driver/features/vehicle/presentation/screens/add_vehicle_screen.dart';
import 'package:saaradhigo_driver/shared/widgets/buttons.dart';

class FakeVehiclesRepository implements VehiclesRepository {
  VehicleRequestDto? lastAddedDto;

  @override
  Future<List<VehicleModel>> getVehicles() async => [];

  @override
  Future<void> switchActiveVehicle(int vehicleId) async {}

  @override
  Future<VehicleModel> updateVehicle(
    int vehicleId,
    Map<String, dynamic> data,
  ) async => const VehicleModel(
    id: 1,
    vehicleNumber: 'TS07AB1234',
    vehicleType: 'sedan',
  );

  @override
  Future<VehicleModel> addVehicle(
    VehicleRequestDto dto, {
    dynamic onProgress,
  }) async {
    lastAddedDto = dto;
    return VehicleModel(
      id: 101,
      vehicleNumber: dto.registrationNumber,
      vehicleType: dto.vehicleType,
      brand: dto.make,
      model: dto.model,
    );
  }
}

void main() {
  testWidgets(
    'AddVehicleScreen renders title, chips, inputs, and action buttons',
    (tester) async {
      final fakeRepo = FakeVehiclesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [vehiclesRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(home: AddVehicleScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Title & Description
      expect(find.text('Add New Vehicle'), findsOneWidget);
      expect(find.text('Vehicle Details'), findsOneWidget);

      // Verify Category Chips
      expect(find.text('SEDAN'), findsOneWidget);
      expect(find.text('SUV'), findsOneWidget);
      expect(find.text('HATCHBACK'), findsOneWidget);
      expect(find.text('AUTO'), findsOneWidget);
      expect(find.text('BIKE'), findsOneWidget);

      // Verify Form Inputs
      expect(find.text('Brand / Make'), findsOneWidget);
      expect(find.text('Model Name'), findsOneWidget);
      expect(find.text('License Plate / Registration Number'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      expect(find.text('Exterior Color'), findsOneWidget);

      // Verify Document Upload Cards
      expect(find.text('Registration Certificate (RC)'), findsOneWidget);
      expect(find.text('Vehicle Front/Side Photo'), findsOneWidget);

      // Verify Submit & Cancel Buttons
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text('Register & Set Active Vehicle'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    },
  );

  testWidgets('AddVehicleScreen shows validation errors on empty submit', (
    tester,
  ) async {
    final fakeRepo = FakeVehiclesRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [vehiclesRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: AddVehicleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap submit button without filling fields
    final submitButton = find.text('Register & Set Active Vehicle');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify form validation errors appear
    expect(find.text('Brand is required'), findsOneWidget);
    expect(find.text('Model is required'), findsOneWidget);
    expect(find.text('License plate number is required'), findsOneWidget);
  });

  testWidgets(
    'AddVehicleScreen shows Discard Changes dialog when form is dirty',
    (tester) async {
      final fakeRepo = FakeVehiclesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [vehiclesRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(home: AddVehicleScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Enter a brand
      final brandField = find.widgetWithText(
        TextFormField,
        'e.g. Maruti Suzuki, Hyundai',
      );
      await tester.enterText(brandField, 'Maruti Suzuki');
      await tester.pumpAndSettle();

      // Tap back button in AppBar
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify Discard Changes dialog appears
      expect(find.text('Discard Changes?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    },
  );
}
