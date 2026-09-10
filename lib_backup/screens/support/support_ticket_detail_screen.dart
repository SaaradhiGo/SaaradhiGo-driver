import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';

class SupportTicketDetailScreen extends StatelessWidget {
  const SupportTicketDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Ticket #TK-84920', showBackButton: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            // Status Header Card
            GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fare Adjustment Inquiry',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'IN PROGRESS',
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created on Oct 22, 2026',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Messages Thread
            _buildThreadBubble(
              isAgent: false,
              sender: 'You',
              time: 'Oct 22, 4:30 PM',
              text:
                  'The trip fare for #TR-1049 was calculated incorrectly due to a route detachment. Please review.',
            ),
            const SizedBox(height: AppSpacing.stackMd),
            _buildThreadBubble(
              isAgent: true,
              sender: 'SaaradhiGo Support Agent',
              time: 'Oct 22, 5:15 PM',
              text:
                  'Hello Vikram, our team is reviewing the GPS route log for trip #TR-1049. An adjustment will be processed within 24 hours.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadBubble({
    required bool isAgent,
    required String sender,
    required String time,
    required String text,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      backgroundColor: isAgent
          ? AppColors.surfaceContainerHigh
          : const Color(0xFF151515).withValues(alpha: 0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sender,
                style: AppTypography.bodyMd.copyWith(
                  color: isAgent ? AppColors.primary : AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                time,
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
