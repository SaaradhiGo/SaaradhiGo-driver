import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/notification_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsNotifierProvider.notifier).fetchNotifications();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        title: Text(
          'Notifications',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              icon: const Icon(
                Icons.done_all_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              label: Text(
                'Mark All Read',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => ref
                  .read(notificationsNotifierProvider.notifier)
                  .markAllAsRead(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
            onPressed: () => ref
                .read(notificationsNotifierProvider.notifier)
                .fetchNotifications(refresh: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter Chips Bar
            _buildCategoryChips(state),
            // Main List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainer,
                onRefresh: () => ref
                    .read(notificationsNotifierProvider.notifier)
                    .fetchNotifications(refresh: true),
                child: _buildContent(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(NotificationsState state) {
    final categories = NotificationCategory.values;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.margin,
        vertical: AppSpacing.unit,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = state.selectedCategory == cat;

          return ChoiceChip(
            label: Text(cat.label),
            selected: isSelected,
            showCheckmark: false,
            labelStyle: AppTypography.labelCaps.copyWith(
              color: isSelected
                  ? AppColors.background
                  : AppColors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surfaceContainer,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
            onSelected: (_) => ref
                .read(notificationsNotifierProvider.notifier)
                .setCategory(cat),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotificationsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.hasError && state.notifications.isEmpty) {
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
                'Failed to load notifications',
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
                    .read(notificationsNotifierProvider.notifier)
                    .fetchNotifications(),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty || state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'All Caught Up!',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                'No new notifications right now.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                text: 'Refresh',
                onPressed: () => ref
                    .read(notificationsNotifierProvider.notifier)
                    .fetchNotifications(refresh: true),
              ),
            ],
          ),
        ),
      );
    }

    // Group notifications by date
    final now = DateTime.now();
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final earlier = <NotificationModel>[];

    for (final item in state.notifications) {
      final date = item.createdAt;
      if (date == null) {
        earlier.add(item);
        continue;
      }
      final diffDays = now.difference(date).inDays;
      if (diffDays == 0 && date.day == now.day) {
        today.add(item);
      } else if (diffDays <= 1 || (diffDays == 0 && date.day != now.day)) {
        yesterday.add(item);
      } else {
        earlier.add(item);
      }
    }

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.margin),
      children: [
        if (today.isNotEmpty) ...[
          _buildSectionHeader('NEW TODAY'),
          for (final item in today) ...[
            _buildNotificationCard(context, item),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        if (yesterday.isNotEmpty) ...[
          _buildSectionHeader('YESTERDAY'),
          for (final item in yesterday) ...[
            _buildNotificationCard(context, item),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        if (earlier.isNotEmpty) ...[
          _buildSectionHeader('EARLIER'),
          for (final item in earlier) ...[
            _buildNotificationCard(context, item),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.unit,
      ),
      child: Text(
        title,
        style: AppTypography.labelCaps.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel item) {
    Color iconColor;
    Color iconBg;
    IconData icon;

    switch (item.category) {
      case NotificationCategory.earnings:
        iconColor = AppColors.primary;
        iconBg = AppColors.primaryContainer.withValues(alpha: 0.15);
        icon = Icons.account_balance_wallet_rounded;
      case NotificationCategory.trips:
        iconColor = AppColors.primary;
        iconBg = AppColors.primaryContainer.withValues(alpha: 0.15);
        icon = Icons.directions_car_rounded;
      case NotificationCategory.safety:
        iconColor = AppColors.error;
        iconBg = AppColors.error.withValues(alpha: 0.15);
        icon = Icons.warning_amber_rounded;
      case NotificationCategory.system:
      case NotificationCategory.all:
        iconColor = const Color(0xFF60A5FA);
        iconBg = const Color(0xFF60A5FA).withValues(alpha: 0.15);
        icon = Icons.verified_user_rounded;
    }

    final formattedTime = _formatTime(item.createdAt);

    return InkWell(
      onTap: () => _handleNotificationTap(context, item),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Stack(
            children: [
              // Left accent border for unread notifications
              if (!item.isRead)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.surfaceContainerHigh,
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!item.isRead) const SizedBox(width: 4),
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: AppTypography.bodyLg.copyWith(
                                    color: AppColors.onBackground,
                                    fontWeight: item.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                formattedTime,
                                style: AppTypography.labelCaps.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.message,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Unread dot indicator
                    if (!item.isRead) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _handleNotificationTap(BuildContext context, NotificationModel item) {
    if (!item.isRead) {
      ref.read(notificationsNotifierProvider.notifier).markAsRead(item.id);
    }

    // Deep-linking mapping
    switch (item.category) {
      case NotificationCategory.earnings:
        context.push('/earnings');
      case NotificationCategory.trips:
        context.push('/history');
      case NotificationCategory.safety:
        context.push('/documents');
      case NotificationCategory.system:
      case NotificationCategory.all:
        context.push('/profile');
    }
  }
}
