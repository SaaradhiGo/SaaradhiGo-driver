import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../models/earnings_model.dart';
import '../services/driver_service.dart';
import '../services/auth_service.dart';
import '../services/earnings_service.dart';
import '../services/api_client.dart';
import 'dart:convert';
import 'package:cross_file/cross_file.dart';

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

  Future<void> fetchProfileData({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    
    bool needsRefresh = forceRefresh;
    
    if (!needsRefresh) {
      final cachedProfileData = await AuthService.getStoredUserProfile();
      if (cachedProfileData != null) {
        _userProfile = UserProfileModel.fromJson(cachedProfileData);
      }
    }
    
    notifyListeners();

    try {
      final futures = <Future>[];
      final bool shouldFetchProfile = needsRefresh || _userProfile == null;
      
      if (shouldFetchProfile) {
        futures.add(AuthService.fetchProfile());
      } else {
        futures.add(Future.value(null));
      }
      futures.add(DriverService.getDriverProfile());
      futures.add(EarningsService.getEarningsSummary());

      final results = await Future.wait(futures);

      if (shouldFetchProfile) {
        final authResponse = results[0] as ApiResponse?;
        if (authResponse != null && authResponse.success && authResponse.data != null) {
          final userData = authResponse.data!.containsKey('id') ? authResponse.data! : authResponse.data!['user'];
          if (userData != null) {
            _userProfile = UserProfileModel.fromJson(userData);
          }
        }
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

  Future<bool> uploadAvatar(XFile image) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.updateProfileAvatar(image);
      if (response.success) {
        await fetchProfileData(forceRefresh: true);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Failed to update avatar';
      }
    } catch (e) {
      _error = 'Failed to upload avatar: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
