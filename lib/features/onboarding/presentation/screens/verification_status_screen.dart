import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/driver_profile_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../models/kyc_checklist_item.dart';
import '../widgets/verification_approved_sheet.dart';
import '../widgets/verification_rejection_banner.dart';
import '../widgets/verification_status_row.dart';

/// Screen displaying the driver's onboarding verification waiting room.
///
/// Features dynamic 4-item checklist rows derived from live driver data,
/// actionable document rejection callouts, 30-second background polling,
/// direct link to support hub, sign-out menu, and celebratory approval celebration.
class VerificationStatusScreen extends ConsumerStatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  ConsumerState<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState
    extends ConsumerState<VerificationStatusScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _showingApprovalModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(driverProfileNotifierProvider);
      current.maybeMap(loaded: (s) => _checkApproval(s.profile), orElse: () {});
      ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _stopPolling();
    // Gentle auto-polling every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _checkApproval(DriverProfileModel? profile) {
    if (profile == null ||
        !profile.approved ||
        _showingApprovalModal ||
        !mounted) {
      return;
    }
    _showingApprovalModal = true;
    _stopPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      VerificationApprovedSheet.show(
        context,
        onEnterDashboard: () => context.go('/'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(driverProfileNotifierProvider);
    final isLoading = profileState.maybeMap(
      loading: (_) => true,
      orElse: () => false,
    );

    ref.listen<ProfileState>(driverProfileNotifierProvider, (_, next) {
      next.maybeMap(loaded: (s) => _checkApproval(s.profile), orElse: () {});
    });

    final profile = profileState.maybeMap(
      loaded: (s) => s.profile,
      orElse: () => null,
    );

    final checklistItems = profile != null
        ? KycChecklistItem.fromProfile(profile)
        : <KycChecklistItem>[
            const KycChecklistItem(
              id: 'identity',
              title: 'Identity & Profile Photo',
              icon: Icons.badge,
              status: KycItemStatus.reviewing,
              targetRoute: '/onboarding/personal',
            ),
            const KycChecklistItem(
              id: 'licence',
              title: 'Driving Licence',
              icon: Icons.credit_card,
              status: KycItemStatus.reviewing,
              targetRoute: '/onboarding/licence',
            ),
            const KycChecklistItem(
              id: 'vehicle',
              title: 'Vehicle Registration & RC',
              icon: Icons.directions_car,
              status: KycItemStatus.reviewing,
              targetRoute: '/onboarding/vehicle',
            ),
            const KycChecklistItem(
              id: 'bank',
              title: 'Bank Account & Payout Details',
              icon: Icons.account_balance,
              status: KycItemStatus.reviewing,
              targetRoute: '/onboarding/photo-bank',
            ),
          ];

    final issuesCount = checklistItems
        .where((i) => i.status == KycItemStatus.actionRequired)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Verification Status',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.onSurfaceVariant,
            ),
            color: AppColors.surfaceContainerHigh,
            onSelected: (value) async {
              if (value == 'logout') {
                _stopPolling();
                await ref.read(authNotifierProvider.notifier).logout();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Sign Out',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceContainerHigh,
          onRefresh: () async {
            await ref
                .read(driverProfileNotifierProvider.notifier)
                .fetchProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.margin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),

                // Pulsing Status Hero Indicator
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: issuesCount > 0
                            ? AppColors.error.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: issuesCount > 0
                              ? AppColors.error.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          issuesCount > 0
                              ? Icons.warning_amber_rounded
                              : Icons.hourglass_top,
                          color: issuesCount > 0
                              ? AppColors.error
                              : AppColors.primary,
                          size: 40,
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 96,
                            height: 96,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Header Title & Body
                Text(
                  issuesCount > 0
                      ? 'Action Needed on Verification'
                      : 'Verification in Progress',
                  style: AppTypography.displayLg.copyWith(
                    color: AppColors.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  issuesCount > 0
                      ? 'Please correct the flagged documents below to allow our compliance team to resume review.'
                      : 'Your documents are currently under review by our executive team. This process ensures the highest standards for our network.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Rejection alert banner if issues detected
                if (issuesCount > 0)
                  VerificationRejectionBanner(issuesCount: issuesCount),

                // Submission Summary Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0x15FFFFFF),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Submission Summary',
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.onBackground,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              issuesCount > 0
                                  ? 'STATUS: ACTION'
                                  : 'ETA: 24-48 HRS',
                              style: AppTypography.labelCaps.copyWith(
                                color: issuesCount > 0
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(color: AppColors.outlineVariant),
                      const SizedBox(height: AppSpacing.sm),

                      // Dynamic Checklist Rows
                      for (final item in checklistItems) ...[
                        VerificationStatusRow(
                          item: item,
                          onRemediate: () {
                            // On re-submitting, profile will refresh
                          },
                        ),
                        if (item != checklistItems.last)
                          const Divider(color: Color(0x15FFFFFF), height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Bottom CTAs
                PrimaryButton(
                  text: 'Refresh Status',
                  isLoading: isLoading,
                  onPressed: () {
                    ref
                        .read(driverProfileNotifierProvider.notifier)
                        .fetchProfile();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  text: 'Contact Support',
                  onPressed: () => context.push('/support'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'We will notify you via SMS and Email once the verification is complete.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
