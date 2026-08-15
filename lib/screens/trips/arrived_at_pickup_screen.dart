import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../navigation/route_names.dart';

class ArrivedAtPickupScreen extends StatefulWidget {
  const ArrivedAtPickupScreen({super.key});

  @override
  State<ArrivedAtPickupScreen> createState() => _ArrivedAtPickupScreenState();
}

class _ArrivedAtPickupScreenState extends State<ArrivedAtPickupScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Arrived at Pickup',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rider Info Card
              GlassPanel(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ananya S.', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
                          Text('Waiting at North Gate', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call, color: AppColors.primary),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat, color: AppColors.primary),
                      onPressed: () => Navigator.pushNamed(context, RouteNames.messages),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),

              // OTP Entry Card for Starting Trip
              GlassPanel(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START TRIP OTP',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask rider for their 4-digit PIN to start trip',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: AppTypography.displayLg.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 16,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '0000',
                        hintStyle: AppTypography.displayLg.copyWith(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                          letterSpacing: 16,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Start Trip Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, RouteNames.activeTrip);
                  },
                  child: Text(
                    'START TRIP',
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
