import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/storage_service.dart';
import '../main.dart'; // For navigatorKey
import '../navigation/route_names.dart';

class TripSessionProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;

  int? _tripId;
  String? _currentStatus;
  Map<String, dynamic>? _tripData;

  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get tripId => _tripId;
  String? get currentStatus => _currentStatus;
  Map<String, dynamic>? get tripData => _tripData;

  void setTripData(Map<String, dynamic> data) {
    _tripData = data;
    _tripId = data['trip_id'] ?? data['id'];
    notifyListeners();
  }

  void resumeTrip(Map<String, dynamic> data) {
    setTripData(data);
    if (data.containsKey('status')) {
      _currentStatus = data['status'];
    }
    if (_tripId != null) {
      connect(_tripId!);
    }
    if (_currentStatus != null) {
      _handleStateNavigation(_currentStatus!);
    }
  }

  Future<void> connect(int tripId) async {
    if (_isConnected && _tripId == tripId) return;

    _tripId = tripId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token =
          await StorageService.read(StorageService.keyAccessToken) ??
          'mock_token';
      final url = Uri.parse(
        'ws://localhost:8000/ws/ride/trip/$tripId/?token=$token',
      );

      _channel = WebSocketChannel.connect(url);

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            debugPrint('TripSession WS Message: $data');
            _handleIncomingMessage(data);
          } catch (e) {
            debugPrint('Error parsing TripSession WS message: $e');
          }
        },
        onDone: () {
          _isConnected = false;
          debugPrint('TripSession WS closed');
          notifyListeners();
        },
        onError: (error) {
          debugPrint('TripSession WS error: $error');
          _error = 'Connection error: $error';
          _isConnected = false;
          _isLoading = false;
          notifyListeners();
        },
      );

      _isConnected = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to connect TripSession WS: $e');
      _error = 'Failed to connect: $e';
      _isConnected = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'connection_established') {
      debugPrint('TripSession connected: ${data['message']}');
    } else if (type == 'trip_status_update') {
      _isLoading = false;
      _currentStatus = data['status'];

      // Update trip data with any new info sent by server
      if (_tripData != null) {
        _tripData = {..._tripData!, ...data};
      } else {
        _tripData = data;
      }

      notifyListeners();
      _handleStateNavigation(_currentStatus!);
    }
  }

  void _handleStateNavigation(String status) {
    if (navigatorKey.currentState == null) return;
    final navigator = navigatorKey.currentState!;

    switch (status) {
      case 'accept':
      case 'accepted':
        navigator.pushReplacementNamed(RouteNames.acceptedRide);
        break;
      case 'reached':
        navigator.pushReplacementNamed(RouteNames.arrivedAtPickup);
        break;
      case 'start':
      case 'in_progress':
        navigator.pushReplacementNamed(RouteNames.activeTrip);
        break;
      case 'complete':
      case 'completed':
        navigator.pushReplacementNamed(RouteNames.tripSummary);
        break;
      case 'cancel':
      case 'cancelled':
        // Show snackbar and go to dashboard
        ScaffoldMessenger.of(
          navigator.context,
        ).showSnackBar(const SnackBar(content: Text('Trip was cancelled')));
        clearSession();
        navigator.pushNamedAndRemoveUntil(
          RouteNames.dashboard,
          (route) => false,
        );
        break;
    }
  }

  void _sendAction(Map<String, dynamic> payload) {
    if (_channel != null && _isConnected) {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _channel!.sink.add(jsonEncode(payload));
    } else {
      _error = 'Not connected to trip session';
      notifyListeners();
    }
  }

  void acceptRide() {
    _sendAction({"action": "accept"});
  }

  void markReached() {
    _sendAction({"action": "reached"});
  }

  void startTrip(String otp) {
    _sendAction({"action": "start", "otp": otp});
  }

  void completeTrip() {
    _sendAction({"action": "complete"});
  }

  void cancelTrip() {
    _sendAction({"action": "cancel"});
  }

  void clearSession() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _tripId = null;
    _currentStatus = null;
    _tripData = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
