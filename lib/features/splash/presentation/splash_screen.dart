import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../routing/app_router.dart';
import '../../../ui/sg_brand.dart';
import '../../../ui/sg_tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a startup delay. In the future, this is where we check auth state
    // and initialize core services before redirecting.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // We navigate to home, and the auth_guard in router will correctly
        // bounce unauthenticated users to the login screen.
        context.goNamed(AppRoute.home.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SgFullLogo(height: 160),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: SgColors.goldText),
          ],
        ),
      ),
    );
  }
}
