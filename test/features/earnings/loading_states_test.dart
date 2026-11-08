/// Every signed-in earnings view ends as loaded, empty (zeros), error with
/// Try again, or a clean sign-out: never a dash or dots that wait forever.
///
/// The requests go through the real DioClient (interceptors included) into a
/// stub adapter, so a 401 here takes the same refresh path as on a phone.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:saaradhigo_driver/core/market/app_headers_interceptor.dart';
import 'package:saaradhigo_driver/core/network/api_endpoints.dart';
import 'package:saaradhigo_driver/core/network/dio_client.dart';
import 'package:saaradhigo_driver/core/storage/secure_storage_service.dart';
import 'package:saaradhigo_driver/features/auth/domain/auth_repository.dart';
import 'package:saaradhigo_driver/features/auth/presentation/login_mobile_screen.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_notifier.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_state.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/screens/driver_earnings_tab.dart';
import 'package:saaradhigo_driver/ui/driver_home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Handler = Future<ResponseBody> Function(RequestOptions options);

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);
  _Handler handler;
  final List<String> paths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    paths.add(options.path);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, Object?> _ok(Object data) => {'status': 'success', 'data': data};

/// A brand-new driver: zeros, empty lists, and (before backend #186) no
/// `currency` on the summary.
Future<ResponseBody> _newAccount(RequestOptions o) async {
  switch (o.path) {
    case '/driver/earnings/period/':
      return _json(
        200,
        _ok({
          'period': o.queryParameters['period'],
          'start': '2026-11-08',
          'end': '2026-11-08',
          'gross': '0.00',
          'commission': '0.00',
          'net': '0.00',
          'cash_collected': '0.00',
          'trips': 0,
          'currency': 'INR',
        }),
      );
    case ApiEndpoints.driverEarningsSummary:
      return _json(
        200,
        _ok({
          'total_earned': '0.00',
          'total_trips': 0,
          'today_earned': '0.00',
          'today_trips': 0,
          'today_net': '0.00',
          'today_commission': '0.00',
        }),
      );
    case ApiEndpoints.driverWithdrawalBalance:
      return _json(
        200,
        _ok({
          'available_balance': '0.00',
          'currency': 'INR',
          'blocked': false,
          'minimum_withdrawal': '500.00',
        }),
      );
    case ApiEndpoints.driverEarnings:
    case ApiEndpoints.driverWithdrawalHistory:
      return _json(200, _ok({'results': <Object>[]}));
  }
  return _json(404, {'status': 'error'});
}

void _expectNoPlaceholders() {
  for (final p in ['–', '…', '•••', '...']) {
    expect(find.text(p), findsNothing, reason: 'placeholder "$p" on screen');
  }
}

class _NoopAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  late _StubAdapter adapter;

  setUpAll(() => initializeDateFormatting('en'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureStorageService.resetSessionRevocationCacheForTests();
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'expired-access',
      'refresh_token': 'used-refresh',
    });
    AppIdentity.debugSetVersion('1.0.0');
    adapter = _StubAdapter(_newAccount);
  });

  Future<void> pumpEarnings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final client = DioClient()..dio.httpClientAdapter = adapter;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWithValue(client),
          authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
        ],
        child: const MaterialApp(home: DriverEarningsTab()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('new account: zeros and the empty messages, no placeholder', (
    tester,
  ) async {
    await pumpEarnings(tester);

    expect(find.byKey(const Key('earn_hero_amount')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('earn_hero_amount'))).data,
      '₹0.00',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('earn_ready'))).data,
      '₹0.00',
    );
    expect(find.text('No trips yet'), findsOneWidget);
    expect(
      find.text('Go online to get your first ride request.'),
      findsOneWidget,
    );
    expect(find.text('No payouts yet'), findsOneWidget);
    expect(find.textContaining('0 trips'), findsOneWidget);
    expect(find.byKey(const Key('earn_hero_loading')), findsNothing);
    _expectNoPlaceholders();
  });

  testWidgets('new account on Home: Today ₹0.00 and trips 0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverHomeView(
            map: const SizedBox.expand(),
            online: false,
            statusLabel: 'Offline',
            onMenu: () {},
            earnings: '₹0.00',
            trips: 0,
          ),
        ),
      ),
    );
    expect(find.text('₹0.00'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    _expectNoPlaceholders();
  });

  testWidgets('expired token: refresh refused with 400 signs out to Log in', (
    tester,
  ) async {
    adapter.handler = (o) async => o.path == ApiEndpoints.refreshToken
        ? _json(400, {
            'status': 'error',
            'error': {'code': 'INVALID_TOKEN', 'message': 'Token is invalid'},
          })
        : _json(401, {'detail': 'Token is expired'});
    final client = DioClient()..dio.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        dioClientProvider.overrideWithValue(client),
        authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    // Signed in, with a session the server will no longer honour.
    container.read(authNotifierProvider);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());

    await tester.runAsync(() async {
      await expectLater(
        client.dio.get<void>(ApiEndpoints.driverEarningsSummary),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);
    });

    expect(
      adapter.paths.where((p) => p == ApiEndpoints.refreshToken),
      hasLength(1),
    );
    final auth = container.read(authNotifierProvider);
    expect(auth, isA<AuthUnauthenticated>());
    expect((auth as AuthUnauthenticated).reason, isNotNull);
    expect(await tester.runAsync(SecureStorageService.getAccessToken), isNull);
    // The router redirects AuthUnauthenticated to /login (app_router.dart);
    // the next test shows the message there.
  });

  testWidgets('login shows "log in again" when the session ends', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'a'});
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginMobileScreen()),
      ),
    );
    await tester.pump();
    container.read(authNotifierProvider.notifier).sessionExpired();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Your session has expired. Please log in again.'),
      findsOneWidget,
    );
  });

  testWidgets('API failure: the error state shows and Try again recovers', (
    tester,
  ) async {
    adapter.handler = (o) async => _json(500, {'status': 'error'});
    await pumpEarnings(tester);

    expect(find.text("We couldn't load your earnings."), findsOneWidget);
    expect(find.text("We couldn't load your balance."), findsOneWidget);
    // The rest of the screen still shows.
    expect(find.byKey(const Key('earn_all_history')), findsOneWidget);
    _expectNoPlaceholders();

    adapter.handler = _newAccount;
    await tester.tap(find.byKey(const Key('earn_retry')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text("We couldn't load your earnings."), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('earn_hero_amount'))).data,
      '₹0.00',
    );
  });

  testWidgets('API timeout: skeleton for at most 10 s, then the error', (
    tester,
  ) async {
    final never = Completer<ResponseBody>();
    adapter.handler = (o) => never.future;
    await pumpEarnings(tester);

    expect(find.byKey(const Key('earn_hero_loading')), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("We couldn't load your earnings."), findsOneWidget);

    adapter.handler = _newAccount;
    await tester.tap(find.byKey(const Key('earn_retry')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(
      tester.widget<Text>(find.byKey(const Key('earn_hero_amount'))).data,
      '₹0.00',
    );
  });
}
