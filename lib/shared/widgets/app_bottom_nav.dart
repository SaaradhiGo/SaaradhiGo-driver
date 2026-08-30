import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Item metadata for the main driver bottom navigation bar.
class AppBottomNavItemData {
  const AppBottomNavItemData({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Glassmorphism Bottom Navigation Bar for the SaaradhiGo Driver App.
///
/// Features:
/// - Distinct press/tap scale spring animation (`0.92x` shrink on press).
/// - Dynamic active tab indicator with animated pill background, gold color
///   transition (`#D4AF37`), icon scale boost (`1.15x`), and glowing indicator dot.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<AppBottomNavItemData> items = [
    AppBottomNavItemData(
      route: '/',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppBottomNavItemData(
      route: '/history',
      icon: Icons.route_outlined,
      activeIcon: Icons.route_rounded,
      label: 'Trips',
    ),
    AppBottomNavItemData(
      route: '/earnings',
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
      label: 'Earnings',
    ),
    AppBottomNavItemData(
      route: '/chat',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
    ),
    AppBottomNavItemData(
      route: '/profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 68 + bottomInset,
          padding: EdgeInsets.only(
            bottom: bottomInset,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              return _BottomNavItem(
                key: ValueKey(item.route),
                data: item,
                isActive: currentIndex == index,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatefulWidget {
  const _BottomNavItem({
    super.key,
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  final AppBottomNavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.unit,
          ),
          // decoration: BoxDecoration(
          //   color: isActive
          //       ? AppColors.primary.withValues(alpha: 0.12)
          //       : Colors.transparent,
          //   borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          // ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(
                  isActive ? widget.data.activeIcon : widget.data.icon,
                  size: 22,
                  color: isActive
                      ? AppColors.primaryContainer
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primaryContainer
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                child: Text(widget.data.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
