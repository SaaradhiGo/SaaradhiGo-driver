import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/misconfigured_build_screen.dart';
import 'core/config/app_config.dart';
import 'core/providers.dart';
import 'core/push/push_service.dart';
import 'core/storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Refuse to run a release build that was compiled without its environment, or
  // one pointed at a dev/staging host. Checked before anything else starts: there
  // is no point initialising push or reading storage for a build that must not be
  // used, and a silent QA build is the failure this guards.
  final misconfiguration = AppConfig.misconfiguration;
  if (misconfiguration != null) {
    runApp(MisconfiguredBuildScreen(reason: misconfiguration));
    return;
  }

  // SharedPreferences is the one dependency that must exist before the first
  // frame: the theme setting and the crash-recovery trip snapshot are both
  // read synchronously during the initial build.
  final localStore = await LocalStore.create();

  // Push is best-effort. A missing google-services.json, or a device with no
  // Play Services (common on grey-market handsets), must not stop a driver
  // from working — dispatch also arrives over the WebSocket, and push is the
  // redundant path, not the primary one.
  await PushService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
      ],
      // Wrapped so a non-production build is identifiable in the hand.
      child: const EnvironmentBadge(child: SaaradhiGoDriverApp()),
    ),
  );
}
