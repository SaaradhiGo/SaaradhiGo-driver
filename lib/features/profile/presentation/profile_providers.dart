import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/driver_profile.dart';

/// The driver's server-side record: approval, licence, active vehicle,
/// lockout. Everything that decides whether they may work.
///
/// Auto-disposed so it refetches when the driver returns to a screen that
/// needs it — approval can flip while the app is open, and a driver staring
/// at a stale "pending verification" screen after ops approved them is a
/// support call.
final driverProfileProvider = FutureProvider.autoDispose<DriverProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchProfile();
});

final vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) {
  return ref.watch(profileRepositoryProvider).fetchVehicles();
});
