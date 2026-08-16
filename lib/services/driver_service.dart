import '../models/profile_model.dart';
import 'api_client.dart';

class DriverService {
  /// Fetch driver profile
  static Future<DriverProfileModel?> getDriverProfile() async {
    final response = await ApiClient.get('/driver/driver/profile/');
    
    if (response.success && response.data != null) {
      return DriverProfileModel.fromJson(response.data!);
    }
    return null;
  }
}
