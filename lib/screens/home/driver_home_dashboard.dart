import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../navigation/route_names.dart';
import '../../services/location_provider.dart';
import '../../services/websocket_provider.dart';
import '../../providers/profile_provider.dart';

class DriverHomeDashboardScreen extends StatefulWidget {
  const DriverHomeDashboardScreen({super.key});

  @override
  State<DriverHomeDashboardScreen> createState() => _DriverHomeDashboardScreenState();
}

class _DriverHomeDashboardScreenState extends State<DriverHomeDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _sheetHeightController;
  late Animation<double> _sheetHeightAnimation;
  final MapController _mapController = MapController();
  StreamSubscription? _wsSubscription;
  late LocationProvider _locationProvider;

  @override
  void initState() {
    super.initState();
    _locationProvider = context.read<LocationProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationProvider.initialize();
      _locationProvider.addListener(_onLocationChanged);

      _wsSubscription = context.read<WebSocketProvider>().rideRequestStream.listen((data) {
        if (mounted) {
          Navigator.pushNamed(context, RouteNames.incomingRideRequest, arguments: data);
        }
      });
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _sheetHeightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sheetHeightAnimation = Tween<double>(begin: 130.0, end: 130.0).animate(
      CurvedAnimation(parent: _sheetHeightController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {});
      });
  }

  void _onLocationChanged() {
    if (!mounted) return;
    final locProvider = context.read<LocationProvider>();
    final wsProvider = context.read<WebSocketProvider>();
    if (wsProvider.isOnline && locProvider.currentLocation != null) {
      wsProvider.sendLocationUpdate(
        locProvider.currentLocation!.latitude,
        locProvider.currentLocation!.longitude,
      );
    }
  }

  void _onEarningsDragUpdate(DragUpdateDetails details) {
    _sheetHeightController.stop();
    setState(() {
      double currentHeight = _sheetHeightAnimation.value;
      currentHeight -= details.primaryDelta!;
      currentHeight = currentHeight.clamp(0.0, 240.0);
      _sheetHeightAnimation = Tween<double>(begin: currentHeight, end: currentHeight).animate(_sheetHeightController);
    });
  }

  void _onEarningsDragEnd(DragEndDetails details) {
    double currentHeight = _sheetHeightAnimation.value;
    double targetHeight;
    
    // Determine snap target based on current height
    if (currentHeight > 180.0) {
      targetHeight = 240.0; // Expanded
    } else if (currentHeight < 80.0) {
      targetHeight = 0.0; // Discarded
    } else {
      targetHeight = 130.0; // Collapsed
    }
    
    // Add velocity consideration
    if (details.primaryVelocity! < -500) {
      targetHeight = 240.0; // Fast swipe up -> expand
    } else if (details.primaryVelocity! > 500) {
      if (currentHeight <= 130.0) {
        targetHeight = 0.0; // Fast swipe down from collapsed -> discard
      } else {
        targetHeight = 130.0; // Fast swipe down from expanded -> collapse
      }
    }

    _sheetHeightAnimation = Tween<double>(begin: currentHeight, end: targetHeight).animate(
      CurvedAnimation(parent: _sheetHeightController, curve: Curves.easeOutCubic),
    );
    _sheetHeightController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _locationProvider.removeListener(_onLocationChanged);
    _wsSubscription?.cancel();
    _pulseController.dispose();
    _sheetHeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final isOnline = context.watch<WebSocketProvider>().isOnline;
    final currentLocation = locationProvider.currentLocation ?? const LatLng(17.3850, 78.4867);
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.userProfile;
    final driver = profileProvider.driverProfile;
    final summary = profileProvider.earningsSummary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Interactive Map
          if (locationProvider.currentLocation == null)
            Container(
              color: AppColors.background,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Getting your location...',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentLocation,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.saaradhigo_driver',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation,
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 0.8 + (1.7 * _pulseController.value),
                                child: Opacity(
                                  opacity: 0.8 - (0.8 * _pulseController.value),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          
          // 2. Top Compact Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerMargin,
                      vertical: AppSpacing.stackMd,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515).withValues(alpha: 0.85),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: AppColors.surfaceVariant,
                                backgroundImage: user?.avatar != null 
                                  ? NetworkImage(user!.avatar!.startsWith('http') ? user.avatar! : 'https://dev.api.saaradhigo.in${user.avatar}')
                                  : null,
                                child: user?.avatar == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.gutter),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'Driver',
                                  style: AppTypography.headlineSm.copyWith(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      driver?.ratings ?? 'N/A',
                                      style: AppTypography.dataMono.copyWith(
                                        color: AppColors.primaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: AppColors.primaryContainer,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.2),
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.notifications,
                              color: AppColors.onSurface,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pushNamed(context, RouteNames.notifications),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 3. Map Controls (Floating Right)
          Positioned(
            top: 130, // roughly top-32
            right: AppSpacing.containerMargin,
            child: Column(
              children: [
                _buildGlassButton(Icons.explore, onPressed: () {}),
                const SizedBox(height: AppSpacing.stackSm),
                _buildGlassButton(Icons.my_location, onPressed: () {
                  if (locationProvider.currentLocation != null) {
                    _mapController.move(locationProvider.currentLocation!, 15.0);
                  }
                }),
              ],
            ),
          ),
          
          // 4. Online/Offline Toggle (Floating Top)
          Positioned(
            top: 100, // Below the header
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final wsProvider = context.read<WebSocketProvider>();
                  if (wsProvider.isOnline) {
                    wsProvider.disconnect();
                  } else {
                    if (locationProvider.currentLocation != null) {
                      wsProvider.connect(locationProvider.currentLocation!.latitude, locationProvider.currentLocation!.longitude);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please wait for location to be fetched')),
                      );
                    }
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isOnline 
                              ? AppColors.primaryContainer 
                              : AppColors.primaryContainer.withValues(alpha: 0.4),
                        ),
                        boxShadow: isOnline ? [
                          BoxShadow(
                            color: AppColors.primaryContainer.withValues(alpha: 0.3),
                            blurRadius: 12,
                          )
                        ] : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? AppColors.primaryContainer : AppColors.surfaceVariant,
                              boxShadow: isOnline ? [
                                BoxShadow(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                )
                              ] : [],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.gutter),
                          Text(
                            isOnline ? "You're Online" : "You're Offline",
                            style: AppTypography.headlineMd.copyWith(
                              color: isOnline ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                              fontWeight: isOnline ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 5. SOS FAB
          Positioned(
            bottom: 280, // matched absolute bottom positioning
            left: AppSpacing.containerMargin,
            child: Container(
              width: 56, // w-14
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.errorContainer.withValues(alpha: 0.4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.sos,
                  color: AppColors.onErrorContainer,
                  size: 28,
                ),
                onPressed: () => Navigator.pushNamed(context, RouteNames.safetyCenter),
              ),
            ),
          ),
          
          // 6. Bottom Earnings Sheet
          if (_sheetHeightAnimation.value > 0)
            Positioned(
              bottom: 80, // bottom-20 (above bottom nav)
              left: AppSpacing.containerMargin,
              right: AppSpacing.containerMargin,
              height: _sheetHeightAnimation.value,
              child: GestureDetector(
                onVerticalDragUpdate: _onEarningsDragUpdate,
                onVerticalDragEnd: _onEarningsDragEnd,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.stackMd),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Grabber
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TODAY'S EARNINGS",
                                      style: AppTypography.labelCaps.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${summary?.todayEarned ?? '0.00'}',
                                      style: AppTypography.displayLg.copyWith(
                                        color: AppColors.primaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.center,
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () => Navigator.pushNamed(context, RouteNames.earnings),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${summary?.todayTrips ?? 0} rides',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.outlineVariant,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '7h 24m online',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Metrics Grid (Revealed when expanded)
                            if (_sheetHeightAnimation.value > 140) ...[
                              const SizedBox(height: AppSpacing.stackSm),
                              Opacity(
                                opacity: ((_sheetHeightAnimation.value - 140) / (240 - 140)).clamp(0.0, 1.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard('ACCEPTANCE', '98%', true),
                                    ),
                                    const SizedBox(width: AppSpacing.stackSm),
                                    Expanded(
                                      child: _buildMetricCard('CANCELLATION', '2%', false),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
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

  Widget _buildGlassButton(IconData icon, {VoidCallback? onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 48, // w-12
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF151515).withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: AppColors.onSurface,
            ),
            onPressed: onPressed ?? () {},
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.dataMono.copyWith(
              color: isPrimary ? AppColors.primary : AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
