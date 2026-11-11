import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';

void main() {
  group('DriverProfileModel deserialization resilience', () {
    test(
      'parses real backend response when status and approved are omitted',
      () {
        final json = <String, dynamic>{
          'id': 15,
          'license_doc': 'https://example.com/doc.jpg',
          'license_doc_back': 'https://example.com/doc_back.jpg',
          'license_expiry': '2023-12-18',
          'active_vehicle': 9,
          'active_vehicle_details': {
            'id': 9,
            'vehicle_number': 'AP 01 AA 9542',
            'brand': '',
            'model': 'cb shine',
            'color': 'Black',
            'year': 2023,
            'capacity': 1,
            'vehicle_pic': null,
          },
        };

        final profile = DriverProfileModel.fromJson(json);
        expect(profile.id, 15);
        expect(profile.status, DriverStatus.offline);
        expect(profile.approved, isFalse);
        expect(profile.licenseDocBack, 'https://example.com/doc_back.jpg');
        expect(profile.activeVehicle, 9);
        expect(profile.activeVehicleDetails?['model'], 'cb shine');
      },
    );

    test('handles user as integer ID or null safely', () {
      final jsonWithIntUser = <String, dynamic>{'id': 15, 'user': 1};

      final profile = DriverProfileModel.fromJson(jsonWithIntUser);
      expect(profile.user?.id, 1);
    });

    test('handles empty or invalid license_expiry safely without throwing', () {
      final json = <String, dynamic>{'id': 15, 'license_expiry': ''};

      final profile = DriverProfileModel.fromJson(json);
      expect(profile.licenseExpiry, isNull);
    });

    test(
      'handles unknown status values gracefully with fallback to offline',
      () {
        final json = <String, dynamic>{
          'id': 15,
          'status': 'unknown_status_from_backend',
        };

        final profile = DriverProfileModel.fromJson(json);
        expect(profile.status, DriverStatus.offline);
      },
    );
  });
}
