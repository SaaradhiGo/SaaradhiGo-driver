import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/vehicle_model.dart';
import '../../../../shared/widgets/app_server_image.dart';
import '../../../../shared/widgets/bottom_sheet_container.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../providers/vehicle_info_providers.dart';

class VehicleInfoScreen extends ConsumerStatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  ConsumerState<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends ConsumerState<VehicleInfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehicleInfoNotifierProvider.notifier).fetchVehicleInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleInfoNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        title: Text(
          'Vehicle & Assets',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
        actions: [
          if (state.allVehicles.length > 1)
            TextButton.icon(
              icon: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              label: Text(
                'Fleet (${state.allVehicles.length})',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _showFleetSelectorSheet(context, state),
            ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Add Vehicle',
            onPressed: () => context.push('/vehicle/add'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
            onPressed: () => ref
                .read(vehicleInfoNotifierProvider.notifier)
                .fetchVehicleInfo(refresh: true),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceContainer,
          onRefresh: () => ref
              .read(vehicleInfoNotifierProvider.notifier)
              .fetchVehicleInfo(refresh: true),
          child: _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, VehicleInfoState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.hasError && state.activeVehicle == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 54,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Failed to load vehicle details',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.errorMessage ??
                    'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Retry',
                onPressed: () => ref
                    .read(vehicleInfoNotifierProvider.notifier)
                    .fetchVehicleInfo(),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty || state.activeVehicle == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_car_outlined,
                color: AppColors.onSurfaceVariant,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No Active Vehicle Registered',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add your vehicle during onboarding or contact SaaradhiGo support.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: '+ Add Vehicle',
                onPressed: () => context.push('/vehicle/add'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                text: 'Refresh',
                onPressed: () => ref
                    .read(vehicleInfoNotifierProvider.notifier)
                    .fetchVehicleInfo(refresh: true),
              ),
            ],
          ),
        ),
      );
    }

    final vehicle = state.activeVehicle!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.margin),
      children: [
        // Page Header
        Text(
          'Active Fleet Vehicle',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your vehicle specifications, registration, and inspection status.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Hero Vehicle Card
        _buildHeroVehicleCard(vehicle),
        const SizedBox(height: AppSpacing.lg),

        // Assets & Compliance Bento Grid
        _buildAssetsBento(vehicle),
        const SizedBox(height: AppSpacing.lg),

        // Vehicle Specifications Grid
        _buildSpecGrid(vehicle),
        const SizedBox(height: AppSpacing.xl),

        // Action Buttons
        PrimaryButton(
          text: 'Update Vehicle Documents',
          onPressed: () => context.push('/documents'),
        ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          text: 'View Inspection Report',
          onPressed: () => _showInspectionBottomSheet(context, vehicle),
        ),
        if (state.allVehicles.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            icon: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.primary,
            ),
            label: const Text('Switch Active Fleet Vehicle'),
            onPressed: () => _showFleetSelectorSheet(context, state),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeroVehicleCard(VehicleModel vehicle) {
    final brand = vehicle.brand ?? '';
    final model = vehicle.model ?? '';
    final nameStr = '$brand $model'.trim();
    final displayName = nameStr.isNotEmpty ? nameStr : 'Registered Vehicle';
    final hasPhoto =
        vehicle.vehiclePic != null && vehicle.vehiclePic!.isNotEmpty;

    return GlassPanel(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Visual
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: hasPhoto
                    ? AppServerImage(
                        url: vehicle.vehiclePic!,
                        fit: BoxFit.cover,
                      )
                    : _buildVectorSilhouetteFallback(vehicle.vehicleType),
              ),
              // Bottom gradient shade
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),
              // Active status pill
              Positioned(
                bottom: 12,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4ADE80),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ACTIVE VEHICLE',
                        style: AppTypography.labelCaps.copyWith(
                          color: const Color(0xFF4ADE80),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Details Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicle.vehicleType.toUpperCase(),
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVectorSilhouetteFallback(String category) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'auto':
        icon = Icons.electric_rickshaw_rounded;
      case 'bike':
        icon = Icons.two_wheeler_rounded;
      case 'suv':
        icon = Icons.airport_shuttle_rounded;
      default:
        icon = Icons.directions_car_rounded;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.primaryContainer.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            category.toUpperCase(),
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsBento(VehicleModel vehicle) {
    final insuranceExpiry = vehicle.insuranceExpiry;
    final insuranceText = insuranceExpiry != null
        ? 'Valid till ${insuranceExpiry.day}/${insuranceExpiry.month}/${insuranceExpiry.year}'
        : 'Active Coverage';

    return Row(
      children: [
        Expanded(
          child: GlassPanel(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Insurance',
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insuranceText,
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: GlassPanel(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.car_repair_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Inspection',
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verified Compliant',
                  style: AppTypography.labelCaps.copyWith(
                    color: const Color(0xFF4ADE80),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecGrid(VehicleModel vehicle) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSpecRow(
            label: 'Registration Plate',
            value: vehicle.vehicleNumber,
            isMono: true,
          ),
          _buildSpecRow(
            label: 'Model Year',
            value: vehicle.year != null ? '${vehicle.year}' : 'N/A',
          ),
          _buildSpecRow(label: 'Exterior Color', value: vehicle.color ?? 'N/A'),
          _buildSpecRow(
            label: 'Seating Capacity',
            value: vehicle.capacity != null
                ? '${vehicle.capacity} Persons'
                : 'N/A',
          ),
          _buildSpecRow(
            label: 'Fuel Type',
            value: vehicle.fuelType ?? 'Petrol / CNG',
          ),
          _buildSpecRow(
            label: 'Category',
            value: vehicle.vehicleType.toUpperCase(),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow({
    required String label,
    required String value,
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
                ? AppTypography.dataMono.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  )
                : AppTypography.bodyMd.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }

  void _showFleetSelectorSheet(BuildContext context, VehicleInfoState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BottomSheetContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fleet Vehicles (${state.allVehicles.length})',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                'Select a vehicle to activate for your driving session.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final v in state.allVehicles) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: v.id == state.activeVehicle?.id
                        ? AppColors.primaryContainer.withValues(alpha: 0.15)
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: v.id == state.activeVehicle?.id
                        ? Border.all(color: AppColors.primary)
                        : null,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.directions_car_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      '${v.brand ?? ''} ${v.model ?? ''}'.trim(),
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      v.vehicleNumber,
                      style: AppTypography.dataMono.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    trailing: v.id == state.activeVehicle?.id
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : TextButton(
                            child: const Text('Activate'),
                            onPressed: () async {
                              Navigator.pop(sheetCtx);
                              await ref
                                  .read(vehicleInfoNotifierProvider.notifier)
                                  .switchActiveVehicle(v.id);
                            },
                          ),
                    onTap: v.id == state.activeVehicle?.id
                        ? null
                        : () async {
                            Navigator.pop(sheetCtx);
                            await ref
                                .read(vehicleInfoNotifierProvider.notifier)
                                .switchActiveVehicle(v.id);
                          },
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                label: const Text('Add New Vehicle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  context.push('/vehicle/add');
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showInspectionBottomSheet(BuildContext context, VehicleModel vehicle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BottomSheetContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vehicle Inspection Report',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                'Inspection verification records for ${vehicle.vehicleNumber}',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildInspectionRow('Braking & Safety System', 'PASSED', true),
              _buildInspectionRow('Tyre Tread & Alignment', 'PASSED', true),
              _buildInspectionRow('Lights & Signal Indicators', 'PASSED', true),
              _buildInspectionRow(
                'Pollution Under Control (PUC)',
                'VALID',
                true,
              ),
              _buildInspectionRow('Commercial Permit Status', 'APPROVED', true),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Done',
                onPressed: () => Navigator.pop(sheetCtx),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionRow(String title, String status, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.bodyMd.copyWith(color: AppColors.onBackground),
          ),
          Row(
            children: [
              Icon(
                passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: passed ? const Color(0xFF4ADE80) : AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: AppTypography.labelCaps.copyWith(
                  color: passed ? const Color(0xFF4ADE80) : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
