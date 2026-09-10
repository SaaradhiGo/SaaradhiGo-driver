import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'storage_service.dart';

class WebSocketProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isOnline = false;
  Timer? _locationTimer;
  double? _lastLat;
  double? _lastLng;

  // A StreamController to broadcast specific events like ride requests
  final StreamController<Map<String, dynamic>> _rideRequestController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get rideRequestStream =>
      _rideRequestController.stream;

  bool get isOnline => _isOnline;

  Future<void> connect(double lat, double lng) async {
    if (_isOnline) return;

    try {
      final token =
          await StorageService.read(StorageService.keyAccessToken) ??
          'mock_token';
      print("token - $token");
      final url = Uri.parse(
        'ws://localhost:8000/ws/driver/location/?token=$token&lat=$lat&lng=$lng',
      );

      _channel = WebSocketChannel.connect(url);
      _lastLat = lat;
      _lastLng = lng;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            print(data);
            _handleIncomingMessage(data);
          } catch (e) {
            debugPrint('Error parsing WS message: $e');
          }
        },
        onDone: () {
          _isOnline = false;
          _locationTimer?.cancel();
          notifyListeners();
        },
        onError: (error) {
          debugPrint('WS error: $error');
          _isOnline = false;
          _locationTimer?.cancel();
          notifyListeners();
        },
      );

      _isOnline = true;

      // Send location updates every 5 seconds
      _locationTimer?.cancel();
      _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_lastLat != null && _lastLng != null && _isOnline) {
          _sendLocationData(_lastLat!, _lastLng!);
        }
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to connect WS: $e');
      _isOnline = false;
      _locationTimer?.cancel();
      notifyListeners();
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'ride_request') {
      _rideRequestController.add(data);
    } else if (type == 'connection_established') {
      debugPrint('WS connected successfully: ${data['message']}');
    } else {
      debugPrint('WS message: ${data['message']}');
    }
    // Handle other event types if necessary
  }

  // Update the latest known coordinates and send immediately
  void sendLocationUpdate(double lat, double lng) {
    _lastLat = lat;
    _lastLng = lng;
    if (_isOnline) {
      _sendLocationData(lat, lng);
    }
  }

  void _sendLocationData(double lat, double lng) {
    if (_channel != null) {
      final data = {"lng": lng, "lat": lat};
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _locationTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isOnline = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _channel?.sink.close();
    _rideRequestController.close();
    super.dispose();
  }
}
