import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  List<TripModel> _trips = [];
  bool _isLoading = false;
  String? _error;

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTrips({String status = 'all'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trips = await TripService.getDriverHistory(status: status);
    } catch (e) {
      _error = 'Failed to load trips: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
