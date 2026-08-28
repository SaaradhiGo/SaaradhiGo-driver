import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Notifications',
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            Text(
              'NEW TODAY',
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _buildNotificationCard(
              icon: Icons.account_balance_wallet,
              iconColor: AppColors.primary,
              title: 'Earnings Update',
              time: '10:42 AM',
              body: '₹1,240 added to your wallet for recent trips.',
              isUnread: true,
              showBorderIndicator: true,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _buildNotificationCard(
              icon: Icons.verified_user,
              iconColor: AppColors.primary,
              title: 'Verification Successful',
              time: '8:15 AM',
              body: 'Your driver profile details have been verified and updated.',
              isUnread: true,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              'YESTERDAY',
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _buildNotificationCard(
              icon: Icons.star,
              iconColor: AppColors.primary,
              title: 'Weekend Bonus',
              time: 'Yesterday',
              body: 'Earn extra ₹500 by completing 10 trips this weekend.',
              isUnread: false,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _buildNotificationCard(
              icon: Icons.info,
              iconColor: AppColors.error,
              title: 'Document Expiry',
              time: 'Yesterday',
              body: 'Action Required: Your vehicle insurance is due in 5 days.',
              isUnread: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String body,
    required bool isUnread,
    bool showBorderIndicator = false,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 16,
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
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
