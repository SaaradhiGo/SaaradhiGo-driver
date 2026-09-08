import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/driver_profile_model.dart';

enum KycItemStatus {
  verified,
  reviewing,
  actionRequired,
  notUploaded;

  String get label {
    switch (this) {
      case KycItemStatus.verified:
        return 'Received';
      case KycItemStatus.reviewing:
        return 'Reviewing';
      case KycItemStatus.actionRequired:
        return 'Action Needed';
      case KycItemStatus.notUploaded:
        return 'Not Uploaded';
    }
  }

  Color get color {
    switch (this) {
      case KycItemStatus.verified:
        return AppColors.primary;
      case KycItemStatus.reviewing:
        return AppColors.secondary;
      case KycItemStatus.actionRequired:
        return AppColors.error;
      case KycItemStatus.notUploaded:
        return AppColors.onSurfaceVariant;
    }
  }

  IconData get icon {
    switch (this) {
      case KycItemStatus.verified:
        return Icons.check_circle;
      case KycItemStatus.reviewing:
        return Icons.sync;
      case KycItemStatus.actionRequired:
        return Icons.error_outline;
      case KycItemStatus.notUploaded:
        return Icons.radio_button_unchecked;
    }
  }
}

class KycChecklistItem {
  const KycChecklistItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.status,
    required this.targetRoute,
    this.rejectionReason,
  });

  final String id;
  final String title;
  final IconData icon;
  final KycItemStatus status;
  final String targetRoute;
  final String? rejectionReason;

  bool get isActionRequired =>
      status == KycItemStatus.actionRequired ||
      status == KycItemStatus.notUploaded;

  /// Builds the 4 dynamic KYC items by inspecting the driver profile.
  static List<KycChecklistItem> fromProfile(DriverProfileModel profile) {
    final isGlobalApproved = profile.approved;
    final isGlobalRejected =
        (profile.kycStatus ?? '').toLowerCase() == 'rejected';

    // 1. Personal Identity & Photo
    final hasUserPhoto =
        profile.user?.avatar != null && profile.user!.avatar!.isNotEmpty;
    final hasUserDetails =
        (profile.user?.isUpdated ?? false) ||
        (profile.user?.fullName != null && profile.user!.fullName!.isNotEmpty);
    final identityStatus = isGlobalApproved
        ? KycItemStatus.verified
        : (isGlobalRejected && !hasUserPhoto
              ? KycItemStatus.actionRequired
              : ((hasUserPhoto || hasUserDetails)
                    ? KycItemStatus.verified
                    : KycItemStatus.notUploaded));

    // 2. Driving Licence
    final hasLicenceDoc =
        profile.licenseDoc != null && profile.licenseDoc!.isNotEmpty;
    final isLicenceExpired =
        profile.licenseExpiry != null &&
        profile.licenseExpiry!.isBefore(DateTime.now());
    final licenceStatus = isGlobalApproved
        ? KycItemStatus.verified
        : (isLicenceExpired
              ? KycItemStatus.actionRequired
              : (hasLicenceDoc
                    ? (isGlobalRejected
                          ? KycItemStatus.actionRequired
                          : KycItemStatus.verified)
                    : KycItemStatus.notUploaded));
    final licenceRejection = isLicenceExpired
        ? 'Licence has expired. Please re-upload a valid document.'
        : (isGlobalRejected && licenceStatus == KycItemStatus.actionRequired
              ? 'Licence document was declined during compliance review.'
              : null);

    // 3. Vehicle Registration & RC
    final hasActiveVehicle =
        profile.activeVehicle != null ||
        (profile.activeVehicleDetails != null &&
            profile.activeVehicleDetails!.isNotEmpty);
    final vehicleStatus = isGlobalApproved
        ? KycItemStatus.verified
        : (hasActiveVehicle
              ? KycItemStatus.verified
              : (isGlobalRejected
                    ? KycItemStatus.actionRequired
                    : KycItemStatus.notUploaded));
    final vehicleRejection =
        (isGlobalRejected && vehicleStatus == KycItemStatus.actionRequired)
        ? 'Vehicle registration details require re-verification.'
        : null;

    // 4. Bank Account & Payouts
    final hasBankDetails = profile.user?.isUpdated ?? false || hasActiveVehicle;
    final bankStatus = isGlobalApproved
        ? KycItemStatus.verified
        : (hasBankDetails
              ? KycItemStatus.reviewing
              : KycItemStatus.notUploaded);

    return [
      KycChecklistItem(
        id: 'identity',
        title: 'Identity & Profile Photo',
        icon: Icons.badge,
        status: identityStatus,
        targetRoute: '/onboarding/personal',
        rejectionReason:
            (isGlobalRejected && identityStatus == KycItemStatus.actionRequired)
            ? 'Profile photo unclear or identity details incomplete.'
            : null,
      ),
      KycChecklistItem(
        id: 'licence',
        title: 'Driving Licence',
        icon: Icons.credit_card,
        status: licenceStatus,
        targetRoute: '/onboarding/licence',
        rejectionReason: licenceRejection,
      ),
      KycChecklistItem(
        id: 'vehicle',
        title: 'Vehicle Registration & RC',
        icon: Icons.directions_car,
        status: vehicleStatus,
        targetRoute: '/onboarding/vehicle',
        rejectionReason: vehicleRejection,
      ),
      KycChecklistItem(
        id: 'bank',
        title: 'Bank Account & Payout Details',
        icon: Icons.account_balance,
        status: bankStatus,
        targetRoute: '/onboarding/photo-bank',
      ),
    ];
  }
}
