import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'navigation/route_names.dart';
import 'services/auth_service.dart';
import 'services/location_provider.dart';
import 'services/websocket_provider.dart';

void main() async {
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

  bool isAuthenticated = await AuthService.isAuthenticated();
  String initialRoute = isAuthenticated ? RouteNames.dashboard : RouteNames.login;

  runApp(SaaradhiGoDriverApp(initialRoute: initialRoute));
}

class SaaradhiGoDriverApp extends StatelessWidget {
  final String initialRoute;

  const SaaradhiGoDriverApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => WebSocketProvider()),
      ],
      child: MaterialApp(
        title: 'SaaradhiGo Driver',
        theme: AppTheme.darkTheme,
        initialRoute: initialRoute,
        onGenerateRoute: AppRouter.onGenerateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

