import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';

class SplashScreenAnimated extends StatefulWidget {
  const SplashScreenAnimated({super.key});

  @override
  State<SplashScreenAnimated> createState() => _SplashScreenAnimatedState();
}

class _SplashScreenAnimatedState extends State<SplashScreenAnimated>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late AnimationController _sweepController;
  late AnimationController _logoPulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
    _sweepController.dispose();
    _logoPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Stack(
        children: [
          // Background atmospheric glow
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container with subtle pulse
                    FadeTransition(
                      opacity: _fadeController,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _fadeController,
                          curve: Curves.easeOut,
                        )),
                        child: SizedBox(
                          width: 128,
                          height: 128,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing rings
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _buildPulseRing(0.0),
                                      _buildPulseRing(0.25),
                                    ],
                                  );
                                },
                              ),
                              // Logo Icon
                              AnimatedBuilder(
                                animation: _logoPulseController,
                                builder: (context, child) {
                                  final scale = 1.0 + (_logoPulseController.value * 0.05);
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.outlineVariant.withValues(alpha: 0.3),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryContainer.withValues(alpha: 0.2 + (_logoPulseController.value * 0.3)),
                                            blurRadius: 20 + (_logoPulseController.value * 20),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.explore,
                                          size: 48,
                                          color: AppColors.primaryContainer,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    
                    // Brand Name
                    FadeTransition(
                      opacity: _fadeController,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _fadeController,
                          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                        )),
                        child: Text(
                          'SaaradhiGo',
                          style: AppTypography.displayLg.copyWith(
                            color: AppColors.primaryContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.unit),
                    
                    // Tagline with Shimmer
                    FadeTransition(
                      opacity: _fadeController,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _fadeController,
                          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                        )),
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: const [
                                    AppColors.primaryContainer,
                                    AppColors.primaryFixed,
                                    AppColors.primaryContainer,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  begin: Alignment(-1.0 + 2 * _shimmerController.value, 0.0),
                                  end: Alignment(1.0 + 2 * _shimmerController.value, 0.0),
                                  tileMode: TileMode.clamp,
                                ).createShader(bounds);
                              },
                              child: Text(
                                'Drive. Earn. Grow.',
                                style: AppTypography.bodyLg.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom loading indicator
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fadeController,
                  curve: const Interval(0.9, 1.0, curve: Curves.easeOut),
                )),
                child: Center(
                  child: Container(
                    width: 160,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _sweepController,
                          builder: (context, child) {
                            return Positioned(
                              left: -160 + (_sweepController.value * 320),
                              child: Container(
                                width: 80,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseRing(double delayOffset) {
    double value = (_pulseController.value + delayOffset) % 1.0;
    
    double curvedValue = Curves.easeInOut.transform(value);
    
    double scale = 0.8 + (0.8 * curvedValue);
    
    double opacity = 0.0;
    if (value < 0.5) {
      opacity = value * 0.6;
    } else {
      opacity = 0.3 - ((value - 0.5) * 0.6);
    }

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
