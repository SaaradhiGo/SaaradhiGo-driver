import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../navigation/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shimmerController;

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

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // After splash animation, check auth and navigate
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation to play (~2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isAuthenticated = await AuthService.isAuthenticated();

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, RouteNames.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, RouteNames.login);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background atmospheric glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    blurRadius: 80,
                    spreadRadius: 80,
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
                                      _buildPulseRing(0.5), // delayed effect
                                    ],
                                  );
                                },
                              ),
                              // Logo Icon
                              Container(
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
                                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                      blurRadius: 24,
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
                          curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
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
                          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
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
                                  color: Colors.white, // color must be white for ShaderMask to work correctly with gradient
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
                  curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
                )),
                child: Center(
                  child: Container(
                    width: 128,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment(-1.0 + (_slideController.value * 2.0), 0.0),
                          child: Container(
                            width: 128 / 3,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
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
    
    // cubic-bezier(0.4, 0, 0.6, 1) approximation
    double curvedValue = Curves.easeInOut.transform(value);
    
    // Scale from 0.8 to 1.5
    double scale = 0.8 + (0.7 * curvedValue);
    
    // Opacity: 0 -> 0.2 -> 0
    double opacity = 0.0;
    if (value < 0.5) {
      opacity = value * 0.4; // 0 to 0.2
    } else {
      opacity = 0.2 - ((value - 0.5) * 0.4); // 0.2 to 0
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
              color: AppColors.primaryContainer,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
