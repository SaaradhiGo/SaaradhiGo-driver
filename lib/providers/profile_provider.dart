import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../models/earnings_model.dart';
import '../services/driver_service.dart';
import '../services/auth_service.dart';
import '../services/earnings_service.dart';
import '../services/api_client.dart';
import 'dart:convert';

class ProfileProvider extends ChangeNotifier {
  UserProfileModel? _userProfile;
  DriverProfileModel? _driverProfile;
  EarningsSummaryModel? _earningsSummary;
  bool _isLoading = false;
  String? _error;

  UserProfileModel? get userProfile => _userProfile;
  DriverProfileModel? get driverProfile => _driverProfile;
  EarningsSummaryModel? get earningsSummary => _earningsSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfileData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        AuthService.fetchProfile(),
        DriverService.getDriverProfile(),
        EarningsService.getEarningsSummary(),
      ]);

      final authResponse = results[0] as ApiResponse;
      if (authResponse.success && authResponse.data != null) {
        _userProfile = UserProfileModel.fromJson(authResponse.data!);
      }

      _driverProfile = results[1] as DriverProfileModel?;
      _earningsSummary = results[2] as EarningsSummaryModel?;
    } catch (e) {
      _error = 'Failed to load profile data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
