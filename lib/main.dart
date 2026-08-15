import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'navigation/route_names.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for mobile driver app
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for premium dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF16130B),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const SaaradhiGoDriverApp());
}

class SaaradhiGoDriverApp extends StatelessWidget {
  const SaaradhiGoDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaaradhiGo Driver',
      theme: AppTheme.darkTheme,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
