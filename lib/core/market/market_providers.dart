/// Riverpod access to the market config.
///
/// [marketConfigProvider] rebuilds its watchers whenever the store adopts a new
/// document (start-up fetch, after sign-in). Code that is not a widget reads
/// `MarketConfigStore.instance.current` directly.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'market_config.dart';
import 'market_config_store.dart';

final marketConfigProvider = Provider<MarketConfig>((ref) {
  final store = MarketConfigStore.instance;
  void onChange() => ref.invalidateSelf();
  store.addListener(onChange);
  ref.onDispose(() => store.removeListener(onChange));
  return store.current;
});
