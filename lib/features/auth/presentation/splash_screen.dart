import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../duty/presentation/duty_controller.dart';
import '../../trip/presentation/trip_controller.dart';
import 'auth_controller.dart';

/// Cold-start handshake.
///
/// Order matters and is the whole point of this screen:
///   1. resolve the session (do we have a valid token?)
///   2. reconcile the active trip against the server
///   3. put the driver back on duty if they were on duty when the app died
///
/// Doing 2 before 3 means a driver whose app was killed mid-ride comes back
/// to the trip screen rather than to an empty home with a live rider in the
/// back seat.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await ref.read(authControllerProvider.notifier).restore();
    if (!mounted) return;

    final auth = ref.read(authControllerProvider);
    if (!auth.isSignedIn) {
      context.go(Routes.login);
      return;
    }

    await ref.read(tripControllerProvider.notifier).restore();
    if (!mounted) return;

    // Fire-and-forget: restoring duty can take a few seconds (permissions,
    // GPS fix, socket) and must not hold the driver on a splash screen.
    unawaited(ref.read(dutyControllerProvider.notifier).restoreIfWasOnDuty());

    final hasTrip = ref.read(tripControllerProvider).hasTrip;
    context.go(hasTrip ? Routes.activeTrip : Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.brand,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.local_taxi_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SaaradhiGo Drive',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
