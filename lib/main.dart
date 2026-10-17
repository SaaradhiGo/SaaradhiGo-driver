import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/environment_config.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';
import 'shared/widgets/app_connectivity_host.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load a local .env if the developer has one. This no longer throws when
  // there is none -- `.env` is not a bundled asset any more, so on a device
  // and in CI there is nothing to load and --dart-define supplies the values.
  await EnvironmentConfig.init();

  // Lock to portrait mode for mobile driver app
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for premium dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0B0B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // A release build that cannot say which server it talks to must not pretend
  // to work. EnvironmentConfig.misconfiguration is null for every debug build
  // and for a deliberate QA build (ALLOW_NON_PRODUCTION_HOST); it is non-null
  // only for a release binary compiled without a server, or one pointed at a
  // non-production host without that flag.
  //
  // Before this check existed the misconfiguration getter was dead code: a
  // store build with no --dart-define silently fell back to the dev API and
  // showed a driver a working app full of test data.
  final problem = EnvironmentConfig.misconfiguration;
  if (problem != null) {
    runApp(MisconfiguredApp(message: problem));
    return;
  }

  runApp(const ProviderScope(child: SaaradhiGoDriverApp()));
}

class SaaradhiGoDriverApp extends ConsumerWidget {
  const SaaradhiGoDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SaaradhiGo Driver',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Global offline strip above every route (docs/14_ERROR_HANDLING.md:11),
      // and a QA corner banner when this build does not talk to production --
      // so a test build on a driver's phone can never be mistaken for the
      // real thing during an acceptance pass.
      builder: (context, child) => _withEnvironmentBanner(
        AppConnectivityHost(child: child ?? const SizedBox.shrink()),
      ),
    );
  }

  static Widget _withEnvironmentBanner(Widget child) {
    if (EnvironmentConfig.environmentLabel != 'non-production') return child;
    return Banner(
      message: 'QA',
      location: BannerLocation.topEnd,
      color: const Color(0xFFB00020),
      child: child,
    );
  }
}

/// Shown instead of the app when a release build has no usable server.
///
/// Deliberately not a dialog over a working UI: there is nothing behind it to
/// work with, and a driver needs to be told to stop rather than left to
/// discover that nothing loads.
class MisconfiguredApp extends StatelessWidget {
  const MisconfiguredApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaaradhiGo Driver',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'This build cannot be used',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please report this to the SaaradhiGo team and install a '
                    'build from the official link.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
