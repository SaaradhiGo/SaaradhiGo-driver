import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:saaradhigo_driver/core/storage/token_store.dart';
import 'package:saaradhigo_driver/core/ws/ws_channel.dart';
import 'package:saaradhigo_driver/features/auth/domain/auth_repository.dart';
import 'package:saaradhigo_driver/features/auth/domain/auth_user.dart';
import 'package:saaradhigo_driver/features/earnings/domain/earnings.dart';
import 'package:saaradhigo_driver/features/earnings/domain/earnings_repository.dart';
import 'package:saaradhigo_driver/features/profile/domain/driver_profile.dart';
import 'package:saaradhigo_driver/features/profile/domain/profile_repository.dart';
import 'package:saaradhigo_driver/features/trip/domain/trip.dart';
import 'package:saaradhigo_driver/features/trip/domain/trip_repository.dart';

/// A Dio adapter that answers from a scripted queue instead of the network.
///
/// Preferred over mocking Dio itself: this exercises the real interceptor
/// chain, so the 401-refresh-and-replay path is genuinely under test rather
/// than stubbed out.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter();

  final List<RequestOptions> requests = <RequestOptions>[];
  final List<_Reply> _replies = <_Reply>[];

  /// Queue a reply. Replies are consumed in order; the last one repeats once
  /// the queue is drained, so a test only has to script what it cares about.
  void enqueue({
    int status = 200,
    Map<String, dynamic>? body,
    List<dynamic>? listBody,
  }) {
    _replies.add(_Reply(status, body ?? {}, listBody));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = _replies.length > 1 ? _replies.removeAt(0) : _replies.first;

    final payload = reply.listBody != null
        ? jsonEncode(reply.listBody)
        : jsonEncode(reply.body);

    return ResponseBody.fromString(
      payload,
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Reply {
  _Reply(this.status, this.body, this.listBody);
  final int status;
  final Map<String, dynamic> body;
  final List<dynamic>? listBody;
}

/// In-memory token store — no platform channels, no Keychain.
class FakeTokenStore implements TokenStore {
  FakeTokenStore({this.access, this.refresh});

  String? access;
  String? refresh;
  int writeCount = 0;
  bool cleared = false;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> write({required String access, String? refresh}) async {
    writeCount++;
    this.access = access;
    if (refresh != null) this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    access = null;
    refresh = null;
  }

  @override
  Future<bool> hasSession() async => (access ?? '').isNotEmpty;
}

/// A [WsChannel] whose frames the test drives by hand.
class FakeWsChannel implements WsChannel {
  final _incoming = StreamController<dynamic>.broadcast();

  /// Frames the app sent to the server.
  final List<String> sent = <String>[];
  bool closed = false;

  /// Push a frame as if the server sent it.
  void emit(Map<String, dynamic> frame) => _incoming.add(jsonEncode(frame));

  /// Push a frame the client cannot decode.
  void emitRaw(String raw) => _incoming.add(raw);

  /// Simulate the socket dying — exercises the reconnect path.
  void kill() => _incoming.addError(Exception('connection reset'));

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  void send(String data) => sent.add(data);

  @override
  Future<void> close() async {
    closed = true;
    await _incoming.close();
  }
}

// --- repository fakes -----------------------------------------------------

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.signedIn = false, this.failVerify = false});

  bool signedIn;
  bool failVerify;
  String? lastOtpPhone;
  int logoutCount = 0;

  // Email auth. Recorded so a test can assert what was sent, and scriptable
  // so a test can drive the failure branches.
  String? lastEmailLoginEmail;
  String? lastEmailLoginPassword;
  String? lastEmailLoginMfaCode;
  String? lastPasswordResetEmail;
  Object? emailLoginError;

  static const user = AuthUser(
    id: 7,
    phoneNumber: '+919999000001',
    fullName: 'Test Driver',
    role: 'driver',
  );

  @override
  Future<AuthUser> emailLogin({
    required String email,
    required String password,
    String? mfaCode,
  }) async {
    lastEmailLoginEmail = email;
    lastEmailLoginPassword = password;
    lastEmailLoginMfaCode = mfaCode;
    final error = emailLoginError;
    if (error != null) throw error;
    signedIn = true;
    return user;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    lastPasswordResetEmail = email;
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    lastOtpPhone = phoneNumber;
  }

  @override
  Future<AuthUser> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? deviceToken,
  }) async {
    if (failVerify) throw Exception('Invalid OTP');
    signedIn = true;
    return user;
  }

  @override
  Future<AuthUser> fetchProfile() async {
    if (!signedIn) throw Exception('not signed in');
    return user;
  }

  @override
  Future<AuthUser> updateProfile({String? fullName, String? email}) async =>
      user;

  @override
  Future<void> logout() async {
    logoutCount++;
    signedIn = false;
  }

  @override
  Future<bool> hasSession() async => signedIn;
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.profile);

  DriverProfile profile;

  @override
  Future<DriverProfile> fetchProfile() async => profile;

  @override
  Future<List<Vehicle>> fetchVehicles() async =>
      profile.activeVehicle == null ? const [] : [profile.activeVehicle!];
}

class FakeEarningsRepository implements EarningsRepository {
  FakeEarningsRepository({this.summary = EarningsSummary.empty, this.entries = const []});

  EarningsSummary summary;
  List<EarningEntry> entries;

  @override
  Future<EarningsSummary> fetchSummary() async => summary;

  @override
  Future<List<EarningEntry>> fetchEntries({int page = 1, int pageSize = 50}) async =>
      entries;
}

class FakeTripRepository implements TripRepository {
  FakeTripRepository({this.active});

  Trip? active;
  int cancelCount = 0;

  @override
  Future<Trip?> fetchActiveTrip() async => active;

  @override
  Future<Trip> fetchTrip(int tripId) async =>
      active ?? Trip(id: tripId, status: TripStatus.accepted);

  @override
  Future<void> cancelTrip({
    required int tripId,
    required String reason,
    String? note,
  }) async {
    cancelCount++;
    active = null;
  }

  @override
  Future<String?> receiptPdfUrl(int tripId) async => null;
}

/// Builders for the fixtures tests reach for repeatedly.
DriverProfile buildProfile({
  bool approved = true,
  String status = 'off',
  bool withVehicle = true,
  DateTime? lockoutUntil,
}) {
  return DriverProfile(
    id: 1,
    approved: approved,
    status: status,
    totalTrips: 128,
    rating: 4.82,
    licenseDoc: 'https://example.invalid/licence.pdf',
    licenseExpiry: DateTime.now().add(const Duration(days: 400)),
    fatigueLockoutUntil: lockoutUntil,
    activeVehicle: withVehicle
        ? Vehicle(
            id: 9,
            vehicleNumber: 'TS09AB1234',
            vehicleType: 'sedan',
            brand: 'Maruti',
            model: 'Dzire',
            color: 'White',
            insuranceExpiry: DateTime.now().add(const Duration(days: 200)),
            permitExpiry: DateTime.now().add(const Duration(days: 200)),
            fitnessExpiry: DateTime.now().add(const Duration(days: 200)),
            pucExpiry: DateTime.now().add(const Duration(days: 200)),
          )
        : null,
  );
}

Trip buildTrip({
  int id = 101,
  TripStatus status = TripStatus.accepted,
  String paymentMethod = 'cash',
  String? paymentStatus,
}) {
  return Trip(
    id: id,
    status: status,
    riderName: 'Raja Kumar',
    riderPhone: '+919888800001',
    pickupAddress: 'Ameerpet Metro',
    destinationAddress: 'Hitech City',
    pickupLat: 17.385,
    pickupLng: 78.486,
    destinationLat: 17.44,
    destinationLng: 78.348,
    estimatedFare: '245.50',
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
  );
}
