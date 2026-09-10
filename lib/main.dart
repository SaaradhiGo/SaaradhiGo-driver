import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';
import 'shared/widgets/app_connectivity_host.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before any dependencies are initialized
  await dotenv.load(fileName: ".env");

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
      // Global offline strip above every route (docs/14_ERROR_HANDLING.md:11).
      builder: (context, child) =>
          AppConnectivityHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
