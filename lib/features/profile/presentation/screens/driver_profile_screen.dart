import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/driver_profile_model.dart';
import '../../../../shared/widgets/driver_avatar.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/profile_providers.dart';

/// Driver Profile / Account Suite screen (`/profile`).
class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(driverProfileNotifierProvider);
      if (state is ProfileStateInitial) {
        ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(driverProfileNotifierProvider);

    // Auto-retry a failed profile fetch when connectivity returns
    // (docs/14_ERROR_HANDLING.md:11).
    ref.listen<bool>(isOnlineNetworkProvider, (previous, next) {
      if (previous == true || next != true) return;
      if (ref.read(driverProfileNotifierProvider) is ProfileStateError) {
        ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          'Account Suite',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (profileState) {
          ProfileStateLoading() => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          ProfileStateError(:final message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.margin),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // Explicitly full-width; the theme now only sets a
                      // height floor.
                      minimumSize: const Size.fromHeight(
                        AppSpacing.primaryButtonHeight,
                      ),
                    ),
                    onPressed: () => ref
                        .read(driverProfileNotifierProvider.notifier)
                        .fetchProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          ProfileStateLoaded(:final profile) => RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainer,
            onRefresh: () =>
                ref.read(driverProfileNotifierProvider.notifier).fetchProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  _buildHeader(context, profile),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMetricsRow(profile),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActiveVehicleDetails(profile),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPersonalDetails(profile),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickActions(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DriverProfileModel profile) {
    final fullName = profile.user?.fullName?.trim();
    final displayName = (fullName == null || fullName.isEmpty)
        ? 'Driver Partner'
        : fullName;
    final avatarUrl = profile.user?.avatar;

    return Center(
      child: Column(
        children: [
          DriverAvatar(
            url: avatarUrl,
            fallbackName: displayName,
            size: 96,
            isVerified: profile.approved,
            onTap: () => _pickAndUploadAvatar(context),
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.unit),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => context.push('/elite'),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.unit,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 16,
                        color: AppColors.primaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ELITE PARTNER',
                        style: AppTypography.labelCaps.copyWith(
                          color: AppColors.primaryContainer,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: AppColors.primaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(DriverProfileModel profile) {
    final rating = profile.ratings?.toStringAsFixed(1) ?? '4.8';
    final trips = profile.totalTrips?.toString() ?? '0';

    return Row(
      children: [
        Expanded(
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: AppTypography.dataMono.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rating',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              children: [
                Text(
                  trips,
                  style: AppTypography.dataMono.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trips',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              children: [
                Icon(
                  profile.approved
                      ? Icons.check_circle_rounded
                      : Icons.pending_rounded,
                  size: 18,
                  color: profile.approved
                      ? AppColors.primaryContainer
                      : AppColors.secondary,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.approved ? 'Approved' : 'Pending',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveVehicleDetails(DriverProfileModel profile) {
    final vehicle = profile.activeVehicleDetails;
    final brand = vehicle?['brand']?.toString() ?? '';
    final model = vehicle?['model']?.toString() ?? '';
    final vehicleName = '$brand $model'.trim();
    final vehicleNumber = vehicle?['vehicle_number']?.toString() ?? 'N/A';
    final vehicleTypeMap = vehicle?['vehicle_type'];
    final vehicleType = vehicleTypeMap is Map
        ? (vehicleTypeMap['description']?.toString() ??
              vehicleTypeMap['type']?.toString() ??
              'N/A')
        : 'N/A';
    final color = vehicle?['color']?.toString() ?? '';
    final year = vehicle?['year']?.toString() ?? '';
    final colorYearStr = [color, year].where((s) => s.isNotEmpty).join(' • ');

    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.margin,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.primaryContainer,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Active Vehicle Information',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onBackground,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          if (vehicle == null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.margin),
              child: Text(
                'No active vehicle set',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            _infoRow(
              'Vehicle Model',
              vehicleName.isNotEmpty ? vehicleName : 'N/A',
            ),
            _infoRow('License Plate', vehicleNumber, isMono: true),
            _infoRow('Category', vehicleType),
            _infoRow(
              'Color & Year',
              colorYearStr.isNotEmpty ? colorYearStr : 'N/A',
              isLast: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalDetails(DriverProfileModel profile) {
    final phone = profile.user?.phoneNumber ?? 'N/A';
    final email = profile.user?.email ?? 'N/A';
    final license = profile.licenseDoc != null ? 'Uploaded' : 'Not Uploaded';
    final expiry = profile.licenseExpiry != null
        ? profile.licenseExpiry!.toIso8601String().split('T').first
        : 'N/A';

    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.margin,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryContainer,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Personal Information',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onBackground,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          _infoRow('Phone Number', phone, isMono: true),
          _infoRow('Email', email),
          _infoRow('Licence Document', license),
          _infoRow('Licence Expiry', expiry, isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isMono = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.margin,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.1),
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: isMono
                ? AppTypography.dataMono.copyWith(color: AppColors.onBackground)
                : AppTypography.bodyMd.copyWith(color: AppColors.onBackground),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.military_tech_rounded,
              color: AppColors.primaryContainer,
            ),
            title: Text(
              'Elite Benefits & Tier',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            subtitle: Text(
              'Tier perks, quality scores & qualification status',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () => context.push('/elite'),
          ),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
          ListTile(
            leading: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.primaryContainer,
            ),
            title: Text(
              'Active Vehicle Information',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () => context.push('/vehicle'),
          ),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
          ListTile(
            leading: const Icon(
              Icons.description_rounded,
              color: AppColors.primaryContainer,
            ),
            title: Text(
              'Compliance & Document Vault',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () => context.push('/documents'),
          ),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
          ListTile(
            leading: const Icon(
              Icons.notifications_rounded,
              color: AppColors.primaryContainer,
            ),
            title: Text(
              'Notifications Center',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () => context.push('/notifications'),
          ),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
          ListTile(
            leading: const Icon(
              Icons.security_rounded,
              color: AppColors.primaryContainer,
            ),
            title: Text(
              'Safety & Emergency Center',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () => context.push('/safety'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null && context.mounted) {
      final bytes = await file.readAsBytes();
      await ref
          .read(driverProfileNotifierProvider.notifier)
          .changeAvatar(bytes: bytes, fileName: file.name);
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(
          'Log Out',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of SaaradhiGo?',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: Text(
              'Log Out',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
