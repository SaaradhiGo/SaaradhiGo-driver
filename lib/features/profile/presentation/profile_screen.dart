import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/driver_profile.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final profileAsync = ref.watch(driverProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(driverProfileProvider),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverProfileProvider);
            await ref.read(driverProfileProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _IdentityCard(
                name: auth.user?.displayName ?? 'Driver',
                phone: auth.user?.phoneNumber ?? '',
                rating: profile.rating,
                trips: profile.totalTrips,
              ),
              const SectionHeader(title: 'Verification'),
              _KycCard(profile: profile),
              const SectionHeader(title: 'Vehicle'),
              _VehicleCard(vehicle: profile.activeVehicle),
              const SectionHeader(title: 'Payouts'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DetailRow(
                        label: 'UPI ID',
                        value: profile.upiId?.isNotEmpty == true
                            ? profile.upiId!
                            : 'Not added',
                        valueColor: profile.upiId?.isNotEmpty == true
                            ? null
                            : AppTheme.warning,
                      ),
                      if (profile.upiId?.isNotEmpty != true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Add your UPI ID through SaaradhiGo support to '
                            'receive payouts.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context, ref),
                icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                label: const Text(
                  'Sign out',
                  style: TextStyle(color: AppTheme.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will stop receiving ride requests and will need your OTP to '
          'sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(authControllerProvider.notifier).signOut();
    if (context.mounted) context.go(Routes.login);
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.phone,
    required this.rating,
    required this.trips,
  });

  final String name;
  final String phone;
  final double rating;
  final int trips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.brand.withValues(alpha: 0.18),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'D',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brand,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(2)),
                      const SizedBox(width: 12),
                      Text('$trips trips'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KycCard extends StatelessWidget {
  const _KycCard({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, IconData icon) = switch (profile.kycState) {
      KycState.approved => ('Approved', AppTheme.brand, Icons.verified_rounded),
      KycState.pendingReview => (
          'Under review',
          AppTheme.warning,
          Icons.hourglass_top_rounded
        ),
      KycState.documentsMissing => (
          'Documents needed',
          AppTheme.warning,
          Icons.description_outlined
        ),
      KycState.blocked => ('Blocked', AppTheme.danger, Icons.block_rounded),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'KYC status',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                StatusChip(label: label, color: color),
              ],
            ),
            const Divider(height: 24),
            DetailRow(
              label: 'Driving licence',
              value: profile.hasLicense ? 'On file' : 'Not uploaded',
              valueColor: profile.hasLicense ? null : AppTheme.warning,
            ),
            DetailRow(
              label: 'Licence expiry',
              value: Fmt.day(profile.licenseExpiry),
              valueColor: _expiryColor(profile.licenseExpiry),
            ),
            if (profile.isLockedOut)
              DetailRow(
                label: 'Cooldown ends in',
                value: Fmt.duration(profile.lockoutRemaining!),
                valueColor: AppTheme.warning,
              ),

            // The way out of "Documents needed".
            //
            // This card used to be read-only: it said "Not uploaded" and the
            // app offered no way to change that, so a driver could be
            // onboarded exactly as far as a permanent block. The backend has
            // accepted document uploads all along.
            if (profile.kycState != KycState.approved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('profile_upload_documents'),
                  onPressed: () => context.push(Routes.kycDocuments),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(
                    profile.hasLicense
                        ? 'Update my documents'
                        : 'Upload my documents',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    if (v == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'No active vehicle. You cannot go online until a vehicle is '
                'added and approved on your account.',
              ),
              const SizedBox(height: 12),
              // Previously a dead end: the message named the blocker and the
              // app had no screen that could clear it.
              FilledButton.icon(
                key: const Key('profile_add_vehicle'),
                onPressed: () => context.push(Routes.kycVehicle),
                icon: const Icon(Icons.directions_car, size: 18),
                label: const Text('Add my vehicle'),
              ),
            ],
          ),
        ),
      );
    }

    final expiring = v.expiringWithin(30);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DetailRow(label: 'Vehicle', value: v.displayName),
            DetailRow(label: 'Number', value: v.vehicleNumber),
            DetailRow(label: 'Type', value: Fmt.titleCase(v.vehicleType ?? '—')),
            DetailRow(label: 'Colour', value: Fmt.titleCase(v.color ?? '—')),
            const Divider(height: 24),
            DetailRow(
              label: 'Insurance',
              value: Fmt.day(v.insuranceExpiry),
              valueColor: _expiryColor(v.insuranceExpiry),
            ),
            DetailRow(
              label: 'Permit',
              value: Fmt.day(v.permitExpiry),
              valueColor: _expiryColor(v.permitExpiry),
            ),
            DetailRow(
              label: 'Fitness',
              value: Fmt.day(v.fitnessExpiry),
              valueColor: _expiryColor(v.fitnessExpiry),
            ),
            DetailRow(
              label: 'PUC',
              value: Fmt.day(v.pucExpiry),
              valueColor: _expiryColor(v.pucExpiry),
            ),
            if (expiring.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: AppTheme.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        // The backend's daily sweeper blocks the driver the
                        // moment one of these lapses, so a warning here is
                        // the difference between a planned renewal and a
                        // shift that ends at 6am with no explanation.
                        'Renew your ${expiring.first.label.toLowerCase()} by '
                        '${Fmt.day(expiring.first.expiry)} or you will be '
                        'blocked from going online.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Amber inside 30 days, red once expired.
Color? _expiryColor(DateTime? expiry) {
  if (expiry == null) return null;
  final now = DateTime.now();
  if (expiry.isBefore(now)) return AppTheme.danger;
  if (expiry.difference(now).inDays <= 30) return AppTheme.warning;
  return null;
}
