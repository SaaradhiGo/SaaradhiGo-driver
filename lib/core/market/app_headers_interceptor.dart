/// The one interceptor every API request goes through.
///
/// - Adds `X-App-Version`, `X-App-Platform` and `X-App-Name: driver` to every
///   request (the backend's version gate, platform_ops/versions.py, only acts
///   when they are present).
/// - Watches errors for `426 APP_UPDATE_REQUIRED` and publishes the store link
///   to [UpdateRequiredState]. The error is passed on UNCHANGED, so nothing
///   else on the request path behaves differently.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Who this build is, as the backend wants to hear it.
class AppIdentity {
  AppIdentity._();

  static const String name = 'driver';
  static String? _version;
  static Future<String>? _loading;

  /// `1.4.2` from the package info; empty if it cannot be read (the backend
  /// ignores a missing version, so the request still works).
  static Future<String> version() {
    if (_version != null) return Future.value(_version);
    return _loading ??= () async {
      try {
        _version = (await PackageInfo.fromPlatform()).version;
      } catch (_) {
        _version = '';
      }
      return _version!;
    }();
  }

  /// `android` or `ios`.
  static String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  @visibleForTesting
  static void debugSetVersion(String? v) {
    _version = v;
    _loading = null;
  }
}

/// A 426 the app must show a blocking screen for.
@immutable
class UpdateRequired {
  const UpdateRequired({this.message, this.storeUrl, this.minimumVersion});

  final String? message;
  final String? storeUrl;
  final String? minimumVersion;
}

class UpdateRequiredState extends ChangeNotifier {
  static final UpdateRequiredState instance = UpdateRequiredState();

  UpdateRequired? _info;
  UpdateRequired? get info => _info;

  void report(UpdateRequired info) {
    _info = info;
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _info = null;
    notifyListeners();
  }
}

/// Reads the 426 envelope: `{status:error, error:{code, message, update:{...}}}`.
/// [data] is the decoded response body (Dio decodes JSON for us).
UpdateRequired? parseUpdateRequired(Object? data) {
  if (data is! Map) return null;
  final error = data['error'];
  if (error is! Map || error['code'] != 'APP_UPDATE_REQUIRED') return null;
  final update = error['update'];
  String? pick(String k) {
    final v = update is Map ? update[k]?.toString().trim() : null;
    return (v == null || v.isEmpty) ? null : v;
  }

  final message = error['message']?.toString().trim();
  return UpdateRequired(
    message: (message == null || message.isEmpty) ? null : message,
    storeUrl: pick('store_url'),
    minimumVersion: pick('minimum_version'),
  );
}

class AppHeadersInterceptor extends Interceptor {
  AppHeadersInterceptor([UpdateRequiredState? updateState])
    : _update = updateState ?? UpdateRequiredState.instance;

  final UpdateRequiredState _update;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final version = await AppIdentity.version();
    if (version.isNotEmpty) {
      options.headers.putIfAbsent('X-App-Version', () => version);
    }
    options.headers.putIfAbsent('X-App-Platform', () => AppIdentity.platform);
    options.headers.putIfAbsent('X-App-Name', () => AppIdentity.name);
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 426) {
      final info = parseUpdateRequired(err.response?.data);
      if (info != null) _update.report(info);
    }
    handler.next(err);
  }
}
