import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class VerificationStatusScreen extends ConsumerWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(driverProfileNotifierProvider);
    final isLoading = profileState.maybeMap(
      loading: (_) => true,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading Icon with Pulse
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.hourglass_top,
                            color: AppColors.primary,
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
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Verification in Progress',
                      style: AppTypography.displayLg.copyWith(
                        color: AppColors.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your documents are currently under review by our executive team. This process ensures the highest standards for our network.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

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
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ETA: 24-48 HRS',
                                  style: AppTypography.labelCaps.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(color: AppColors.outlineVariant),
                          const SizedBox(height: AppSpacing.sm),
                          _buildStatusRow(Icons.badge, 'Identity Proof', true),
                          _buildStatusRow(
                            Icons.directions_car,
                            'Vehicle Registration',
                            true,
                          ),
                          _buildStatusRow(
                            Icons.policy,
                            'Insurance Policy',
                            false,
                          ),
                          _buildStatusRow(
                            Icons.history_edu,
                            'Background Check',
                            false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              Column(
                children: [
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
                  SecondaryButton(text: 'Contact Support', onPressed: () {}),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'We will notify you via SMS and Email once the verification is complete.',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String title, bool isReceived) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                isReceived ? Icons.check_circle : Icons.sync,
                color: isReceived ? AppColors.primary : AppColors.secondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isReceived ? 'Received' : 'Reviewing',
                style: AppTypography.labelCaps.copyWith(
                  color: isReceived ? AppColors.primary : AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
