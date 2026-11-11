import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/features/onboarding/presentation/models/kyc_checklist_item.dart';

void main() {
  group('KycChecklistItem.fromProfile', () {
    test('marks all items verified when profile is approved', () {
      final profile = DriverProfileModel(
        id: 1,
        approved: true,
        user: const UserModel(
          id: 1,
          fullName: 'Ravi Kumar',
          avatar: 'https://cdn/pic.jpg',
        ),
        licenseDoc: 'https://cdn/dl.jpg',
        activeVehicle: 10,
      );

      final items = KycChecklistItem.fromProfile(profile);
      expect(items.length, 4);
      expect(items.every((i) => i.status == KycItemStatus.verified), isTrue);
      expect(items.any((i) => i.isActionRequired), isFalse);
    });

    test('marks items not uploaded for empty fresh profile', () {
      const profile = DriverProfileModel(id: 1, approved: false);

      final items = KycChecklistItem.fromProfile(profile);
      expect(items.length, 4);

      final licenceItem = items.firstWhere((i) => i.id == 'licence');
      expect(licenceItem.status, KycItemStatus.notUploaded);
      expect(licenceItem.isActionRequired, isTrue);

      final vehicleItem = items.firstWhere((i) => i.id == 'vehicle');
      expect(vehicleItem.status, KycItemStatus.notUploaded);
    });

    test('flags expired driving licence as actionRequired', () {
      final profile = DriverProfileModel(
        id: 1,
        approved: false,
        licenseDoc: 'https://cdn/dl.jpg',
        licenseExpiry: DateTime.now().subtract(const Duration(days: 10)),
        activeVehicle: 5,
      );

      final items = KycChecklistItem.fromProfile(profile);
      final licenceItem = items.firstWhere((i) => i.id == 'licence');

      expect(licenceItem.status, KycItemStatus.actionRequired);
      expect(licenceItem.rejectionReason, contains('expired'));
      expect(licenceItem.targetRoute, '/onboarding/licence');
    });

    test('marks items as actionRequired when kycStatus is rejected', () {
      const profile = DriverProfileModel(
        id: 1,
        approved: false,
        kycStatus: 'rejected',
        licenseDoc: 'https://cdn/dl_blurry.jpg',
      );

      final items = KycChecklistItem.fromProfile(profile);
      final licenceItem = items.firstWhere((i) => i.id == 'licence');

      expect(licenceItem.status, KycItemStatus.actionRequired);
      expect(licenceItem.rejectionReason, isNotNull);
    });
  });
}
