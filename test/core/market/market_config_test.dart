/// App catch-up D9 + D6: the market config (app-config), the version headers,
/// the 426 update screen, notices, and the screens that used to hard-code India.
///
/// Fixtures are copied from the backend serializer (test/support/
/// app_config_fixtures.dart). Nothing here calls a real server.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/market/app_headers_interceptor.dart';
import 'package:saaradhigo_driver/core/market/market_config.dart';
import 'package:saaradhigo_driver/core/market/market_config_store.dart';
import 'package:saaradhigo_driver/core/network/dio_client.dart';
import 'package:saaradhigo_driver/core/storage/secure_storage_service.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/features/auth/domain/auth_repository.dart';
import 'package:saaradhigo_driver/features/auth/presentation/login_mobile_screen.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/widgets/earnings_breakdown_card.dart';
import 'package:saaradhigo_driver/features/onboarding/presentation/screens/onboarding_personal_screen.dart';
import 'package:saaradhigo_driver/features/support/presentation/screens/safety_center_screen.dart';
import 'package:saaradhigo_driver/shared/widgets/market_overlays.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/app_config_fixtures.dart';

/// A Dio adapter that answers from a function and records every request.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> seen = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    seen.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _body(Object json, [int status = 200]) => ResponseBody.fromString(
  json is String ? json : jsonEncode(json),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

MarketConfigStore _store(
  Future<ResponseBody> Function(RequestOptions) handler, {
  Duration timeout = const Duration(seconds: 2),
  _Adapter? adapter,
}) {
  final a = adapter ?? _Adapter(handler);
  final dio = Dio(BaseOptions(
    baseUrl: 'https://qa.example/api/v1',
    validateStatus: (_) => true,
  ))..httpClientAdapter = a;
  dio.interceptors.add(AppHeadersInterceptor());
  return MarketConfigStore(dio: dio, timeout: timeout);
}

MarketConfig _cfg(Map<String, dynamic> body) =>
    MarketConfig.fromData((body['data'] as Map).cast<String, dynamic>());

class _NoAuthRepo implements AuthRepository {
  @override
  Future<void> requestOtp(String phoneNumber) async {}
  @override
  Future<UserModel?> verifyOtp(String phoneNumber, String otp) async => null;
  @override
  Future<UserModel?> emailLogin({
    required String email,
    required String password,
  }) async => null;
  @override
  Future<String> requestPasswordReset(String email) async => '';
  @override
  Future<void> logout() async {}
}

/// Two pre-existing framework complaints that have nothing to do with the
/// market config: the safety centre puts a ListTile under a coloured
/// DecoratedBox (a debug-only assertion), and the onboarding screen calls
/// ref.read inside dispose (a StateError when the tree is torn down). Both are
/// dropped here so these tests assert only on what the market changes.
void _ignoreKnownNoise() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (text.contains('ListTile background color') ||
        text.contains('about to or has been unmounted')) {
      return;
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    SecureStorageService.resetSessionRevocationCacheForTests();
    MarketConfigStore.instance.debugSet(MarketConfig.builtIn, from: 'built-in');
    UpdateRequiredState.instance.clear();
    NoticeBanner.resetDismissed();
    AppIdentity.debugSetVersion('1.4.2');
  });

  group('built-in defaults are today\'s behaviour', () {
    test('India: +91, INR/rupee, km, 112, today\'s safety text', () {
      const c = MarketConfig.builtIn;
      expect(c.dialPrefix, '+91');
      expect(c.currencyCode, 'INR');
      expect(c.currencySymbol, '₹');
      expect(c.distanceUnit, 'km');
      expect(c.emergency.number, '112');
      expect(c.emergencyTitle, 'Police (India)');
      expect(c.emergencySubtitle, 'Dial 112 / 100');
      expect(c.liveCityNames, isEmpty);
      expect(c.notices, isEmpty);
    });

    test('the QA document (India, no notices) parses to the same money and phone',
        () {
      final c = _cfg(indiaBody());
      expect(c.dialPrefix, '+91');
      expect(c.currencySymbol, '₹');
      expect(c.distanceUnit, 'km');
      expect(c.emergency.number, '112');
      expect(c.notices, isEmpty);
      expect(c.liveCityNames, ['Hyderabad']);
    });

    test('symbol helpers: withSymbol / stripSymbol', () {
      const c = MarketConfig.builtIn;
      expect(c.withSymbol('250.00'), '₹250.00');
      expect(c.withSymbol('₹250.00'), '₹250.00');
      expect(c.stripSymbol('₹ 250.00'), '250.00');
      final us = _cfg(usBody());
      expect(us.withSymbol('250.00'), r'$250.00');
      expect(us.stripSymbol(r'$250.00'), '250.00');
    });
  });

  group('fallback order: fresh -> cached -> built-in', () {
    test('a failed fetch with nothing cached stays on built-in', () async {
      final s = _store((_) async => _body('boom', 500));
      await s.restoreCached();
      await s.refresh();
      expect(s.source, 'built-in');
      expect(s.current.dialPrefix, '+91');
    });

    test('a good response is adopted and cached; a later failure uses the cache',
        () async {
      final good = _store((_) async => _body(usBody()));
      await good.refresh(country: 'US');
      expect(good.source, 'fresh');
      expect(good.current.dialPrefix, '+1');

      final next = _store((_) async => throw Exception('offline'));
      await next.restoreCached();
      expect(next.source, 'cached');
      expect(next.current.currencySymbol, r'$');
      await next.refresh();
      expect(next.source, 'cached', reason: 'a failed fetch keeps the cache');
    });

    test('an unknown country (404) keeps the cached/built-in config, no crash',
        () async {
      final notFound = {
        'status': 'error',
        'error': {
          'code': 'UNKNOWN_COUNTRY',
          'message': "Unknown country 'ZZ'.",
          'details': {'field': 'country', 'issue': 'x'},
        },
      };
      final s = _store((_) async => _body(notFound, 404));
      await s.refresh(country: 'ZZ');
      expect(s.source, 'built-in');
      expect(s.current.countryCode, 'IN');

      final cached = _store((_) async => _body(usBody()));
      await cached.refresh(country: 'US');
      final again = _store((_) async => _body(notFound, 404));
      await again.restoreCached();
      await again.refresh(country: 'ZZ');
      expect(again.current.countryCode, 'US');
    });

    test('a timeout never blocks and keeps what it had', () async {
      final s = _store(
        (_) => Completer<ResponseBody>().future,
        timeout: const Duration(milliseconds: 50),
      );
      final c = await s.refresh();
      expect(c.countryCode, 'IN');
      expect(s.source, 'built-in');
    });

    test('a garbage body is ignored', () async {
      final s = _store((_) async => _body('<html>', 200));
      await s.refresh();
      expect(s.source, 'built-in');
    });

    test('country: last known first, IN only as the last fallback', () async {
      final seen = <String>[];
      Future<ResponseBody> handler(RequestOptions o) async {
        seen.add(o.queryParameters['country'] as String);
        expect(o.queryParameters['app'], 'driver');
        expect(o.path, '/app-config/');
        return _body(seen.length == 1 ? usBody() : indiaBody());
      }

      final s = _store(handler);
      await s.refresh();
      expect(seen.last, 'IN');
      await s.refresh(country: 'US');
      expect(seen.last, 'US');
      final fresh = _store(handler);
      await fresh.restoreCached();
      await fresh.refresh();
      expect(seen.last, 'IN');
    });
  });

  group('headers on every request', () {
    test('DioClient puts X-App-* on every API request, method by method',
        () async {
      final adapter = _Adapter((_) async => _body({'status': 'success'}));
      final client = DioClient();
      client.dio.httpClientAdapter = adapter;
      await client.dio.get<dynamic>('/driver/earnings/');
      await client.dio.post<dynamic>('/auth/otp/', data: {'phone': '+911'});
      await client.dio.patch<dynamic>('/auth/update/', data: {});
      expect(adapter.seen, hasLength(3));
      for (final r in adapter.seen) {
        expect(r.headers['X-App-Version'], '1.4.2');
        expect(r.headers['X-App-Platform'], 'android');
        expect(r.headers['X-App-Name'], 'driver');
      }
    });

    test('the app-config fetch itself carries them too', () async {
      final adapter = _Adapter((_) async => _body(indiaBody()));
      final s = _store((_) async => _body(indiaBody()), adapter: adapter);
      await s.refresh();
      expect(adapter.seen.single.headers['X-App-Name'], 'driver');
    });
  });

  group('426 APP_UPDATE_REQUIRED', () {
    test('is published with the store link; the error still reaches the caller',
        () async {
      final adapter = _Adapter((_) async => _body(
        jsonDecode(updateRequiredBody()) as Map<String, dynamic>,
        426,
      ));
      final client = DioClient();
      client.dio.httpClientAdapter = adapter;
      Object? thrown;
      try {
        await client.dio.get<dynamic>('/driver/earnings/');
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isA<DioException>());
      expect((thrown as DioException).response?.statusCode, 426);
      final info = UpdateRequiredState.instance.info!;
      expect(info.storeUrl, contains('play.google.com'));
      expect(info.message, 'Please update the app to continue.');
    });

    test('other errors, and a 426 that is not ours, show nothing', () async {
      final adapter = _Adapter((_) async => _body('proxy says no', 426));
      final client = DioClient();
      client.dio.httpClientAdapter = adapter;
      try {
        await client.dio.get<dynamic>('/x/');
      } catch (_) {}
      expect(UpdateRequiredState.instance.info, isNull);
    });

    testWidgets('the update screen is blocking and has the store button',
        (tester) async {
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: UpdateRequiredScreen(
            info: parseUpdateRequired(
              jsonDecode(updateRequiredBody()) as Map<String, dynamic>,
            )!,
            onOpenStore: (u) async => opened = u,
          ),
        ),
      );
      expect(find.text('Update required'), findsOneWidget);
      await tester.tap(find.byKey(const Key('update_required_button')));
      expect(opened, contains('play.google.com'));
    });

    testWidgets('MarketOverlays shows the update screen over the app and keeps '
        'the app mounted', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MarketOverlays(child: Scaffold(body: Text('THE APP'))),
        ),
      );
      expect(find.text('THE APP'), findsOneWidget);
      UpdateRequiredState.instance.report(
        parseUpdateRequired(
          jsonDecode(updateRequiredBody()) as Map<String, dynamic>,
        )!,
      );
      await tester.pump();
      expect(find.byKey(const Key('update_required_title')), findsOneWidget);
      expect(find.text('THE APP'), findsNothing, reason: 'offstage');
      expect(find.text('THE APP', skipOffstage: false), findsOneWidget);
    });
  });

  group('notices', () {
    testWidgets('a notice shows as a dismissible banner; none shows nothing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MarketOverlays(child: Scaffold(body: Text('THE APP'))),
        ),
      );
      expect(find.byKey(const Key('notice_7')), findsNothing);

      MarketConfigStore.instance.debugSet(
        _cfg(indiaBody(notices: [noticeJson()])),
      );
      await tester.pump();
      expect(find.byKey(const Key('notice_7')), findsOneWidget);
      expect(find.textContaining('Scheduled maintenance'), findsOneWidget);
      expect(find.text('THE APP'), findsOneWidget, reason: 'not blocking');

      await tester.tap(find.byKey(const Key('notice_dismiss_7')));
      await tester.pump();
      expect(find.byKey(const Key('notice_7')), findsNothing);
      expect(find.text('THE APP'), findsOneWidget);
    });

    test('a notice blocks only if it says so', () {
      final c = MarketConfig.fromData({
        'notices': [
          {...noticeJson(id: 1), 'blocking': true},
          noticeJson(id: 2),
        ],
      });
      expect(c.notices.firstWhere((n) => n.id == 1).blocking, isTrue);
      expect(c.notices.firstWhere((n) => n.id == 2).blocking, isFalse);
    });
  });

  group('screens read the market', () {
    Future<void> pumpLogin(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(_NoAuthRepo())],
          child: const MaterialApp(home: LoginMobileScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('India config: the phone field shows +91 exactly as today',
        (tester) async {
      MarketConfigStore.instance.debugSet(_cfg(indiaBody()));
      await pumpLogin(tester);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.decoration?.prefixText, '+91 ');
    });

    testWidgets('US config: the phone field shows +1', (tester) async {
      MarketConfigStore.instance.debugSet(_cfg(usBody()));
      await pumpLogin(tester);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.decoration?.prefixText, '+1 ');
    });

    Future<void> pumpBreakdown(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EarningsBreakdownCard(
                grossFares: '1450.50',
                commission: '145.05',
                netEarnings: '1305.45',
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('India config: earnings render rupees exactly as today',
        (tester) async {
      MarketConfigStore.instance.debugSet(_cfg(indiaBody()));
      await pumpBreakdown(tester);
      expect(find.text('₹1450.50'), findsOneWidget);
      expect(find.text('-₹145.05'), findsOneWidget);
      expect(find.text('₹1305.45'), findsOneWidget);
      expect(find.text('₹0.00'), findsNWidgets(2));
    });

    testWidgets('US config: earnings render dollars', (tester) async {
      MarketConfigStore.instance.debugSet(_cfg(usBody()));
      await pumpBreakdown(tester);
      expect(find.text(r'$1450.50'), findsOneWidget);
      expect(find.text(r'-$145.05'), findsOneWidget);
      expect(find.text(r'$0.00'), findsNWidgets(2));
      expect(find.textContaining('₹'), findsNothing);
    });

    Future<void> pumpOnboarding(WidgetTester tester) async {
      _ignoreKnownNoise();
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1200, 3000);
      view.devicePixelRatio = 1.0;
      addTearDown(() {
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingPersonalScreen()),
        ),
      );
      await tester.pump();
    }

    Future<List<String>> cityItems(WidgetTester tester) async {
      final dropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String>,
      );
      await tester.ensureVisible(dropdown.first);
      await tester.tap(dropdown.first);
      await tester.pumpAndSettle();
      final texts = tester
          .widgetList<DropdownMenuItem<String>>(
            find.byWidgetPredicate((w) => w is DropdownMenuItem<String>),
          )
          .map((i) => (i.child as Text).data!)
          .toList();
      return texts;
    }

    testWidgets('onboarding cities: the built-in list when the server names none',
        (tester) async {
      await pumpOnboarding(tester);
      final items = await cityItems(tester);
      expect(
        items.toSet(),
        {'Mumbai', 'New Delhi', 'Bangalore', 'Hyderabad'},
      );
    });

    testWidgets('onboarding cities: the live cities from app-config',
        (tester) async {
      MarketConfigStore.instance.debugSet(_cfg(usBody()));
      await pumpOnboarding(tester);
      final items = await cityItems(tester);
      expect(items.toSet(), {'Austin'});
    });

    Future<void> pumpSafety(WidgetTester tester) async {
      _ignoreKnownNoise();
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SafetyCenterScreen())),
      );
      await tester.pump();
    }

    testWidgets('safety centre: built-in text is exactly what shipped',
        (tester) async {
      await pumpSafety(tester);
      expect(find.text('Police (India)'), findsOneWidget);
      expect(find.text('Dial 112 / 100'), findsOneWidget);
    });

    testWidgets('safety centre: a configured market uses its own label and number',
        (tester) async {
      MarketConfigStore.instance.debugSet(_cfg(usBody()));
      await pumpSafety(tester);
      expect(find.text('Police (India)'), findsNothing);
      expect(find.text('Emergency services'), findsOneWidget);
      expect(find.text('Dial 911'), findsOneWidget);
    });
  });
}
