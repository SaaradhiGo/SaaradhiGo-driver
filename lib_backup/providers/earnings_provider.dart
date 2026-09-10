import 'package:flutter/material.dart';
import '../models/earnings_model.dart';
import '../services/earnings_service.dart';

class EarningsProvider extends ChangeNotifier {
  EarningsSummaryModel? _summary;
  List<EarningModel> _earningsList = [];
  bool _isLoading = false;
  String? _error;

  EarningsSummaryModel? get summary => _summary;
  List<EarningModel> get earningsList => _earningsList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEarnings({String? period}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await EarningsService.getEarningsSummary(period: period);
      // Depending on the UX, you can fetch earningsList here too
      // _earningsList = await EarningsService.getEarningsList();
    } catch (e) {
      _error = 'Failed to load earnings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
