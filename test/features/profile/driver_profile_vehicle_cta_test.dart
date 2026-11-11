import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/domain/models/vehicle_model.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_notifier.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_providers.dart';
import 'package:saaradhigo_driver/features/profile/presentation/screens/driver_profile_screen.dart';
import 'package:saaradhigo_driver/features/vehicle/presentation/providers/vehicle_info_providers.dart';

void main() {
  const profileWithNoVehicle = DriverProfileModel(
    id: 1,
    user: UserModel(id: 1, fullName: 'Vikram Singh'),
    approved: true,
    ratings: 4.8,
    totalTrips: 120,
    activeVehicleDetails: null,
  );

  const profileWithActiveVehicle = DriverProfileModel(
    id: 1,
    user: UserModel(id: 1, fullName: 'Vikram Singh'),
    approved: true,
    ratings: 4.8,
    totalTrips: 120,
    activeVehicleDetails: {
      'brand': 'Maruti Suzuki',
      'model': 'Swift Dzire',
      'vehicle_number': 'TS09AB1234',
      'color': 'Pearl White',
      'year': 2023,
    },
  );

  testWidgets(
    'DriverProfileScreen renders + Add Vehicle CTA when no active vehicle and fleet is empty',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            driverProfileNotifierProvider.overrideWith(
              () => FakeProfileNotifier(
                ProfileState.loaded(profileWithNoVehicle),
              ),
            ),
            vehicleInfoNotifierProvider.overrideWith(
              () => FakeVehicleInfoNotifier(
                const VehicleInfoState(
                  status: VehicleInfoStatus.empty,
                  allVehicles: [],
                  activeVehicle: null,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: DriverProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Active Vehicle Set'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);
      expect(
        find.text(
          'Register or assign your vehicle to start accepting rides and going online.',
        ),
        findsOneWidget,
      );
      expect(find.text('+ Add Vehicle'), findsOneWidget);
    },
  );

  testWidgets(
    'DriverProfileScreen renders Select Active Vehicle CTA when fleet has vehicles but none active',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            driverProfileNotifierProvider.overrideWith(
              () => FakeProfileNotifier(
                ProfileState.loaded(profileWithNoVehicle),
              ),
            ),
            vehicleInfoNotifierProvider.overrideWith(
              () => FakeVehicleInfoNotifier(
                const VehicleInfoState(
                  status: VehicleInfoStatus.success,
                  allVehicles: [
                    VehicleModel(
                      id: 12,
                      vehicleNumber: 'TS07EF9999',
                      vehicleType: 'sedan',
                      brand: 'Hyundai',
                      model: 'Aura',
                    ),
                  ],
                  activeVehicle: null,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: DriverProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Active Vehicle Set'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);
      expect(find.text('Select Active Vehicle'), findsOneWidget);
    },
  );

  testWidgets(
    'DriverProfileScreen renders Active Vehicle Information when vehicle is set',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            driverProfileNotifierProvider.overrideWith(
              () => FakeProfileNotifier(
                ProfileState.loaded(profileWithActiveVehicle),
              ),
            ),
            vehicleInfoNotifierProvider.overrideWith(
              () => FakeVehicleInfoNotifier(
                const VehicleInfoState(
                  status: VehicleInfoStatus.success,
                  allVehicles: [],
                  activeVehicle: null,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: DriverProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Active Vehicle Information'), findsNWidgets(2));
      expect(find.text('Maruti Suzuki Swift Dzire'), findsOneWidget);
      expect(find.text('TS09AB1234'), findsOneWidget);
      expect(find.text('Pearl White • 2023'), findsOneWidget);
    },
  );
}

class FakeProfileNotifier extends ProfileNotifier {
  FakeProfileNotifier(this._initialState);
  final ProfileState _initialState;

  @override
  ProfileState build() => _initialState;

  @override
  Future<void> fetchProfile() async {}
}

class FakeVehicleInfoNotifier extends VehicleInfoNotifier {
  FakeVehicleInfoNotifier(this._initialState);
  final VehicleInfoState _initialState;

  @override
  VehicleInfoState build() => _initialState;

  @override
  Future<void> fetchVehicleInfo({bool refresh = false}) async {}
}
