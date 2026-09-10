import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Messages / Chat tab screen (`/chat`).
class MessagesChatScreen extends StatelessWidget {
  const MessagesChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          'Messages & Support',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.margin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 56,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No Messages',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  'Passenger chats and support messages will appear here when active.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
