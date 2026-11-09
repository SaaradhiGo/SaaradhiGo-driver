import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../ui/sg_l10n.dart';

/// Calling the rider through the masked call bridge (backend `/calls/`,
/// 9 Nov). The server answers with a temporary number valid for this trip;
/// the dialer opens on that number, never the rider's own. When the driver
/// comes back to the app the call is closed, which records its duration as
/// a trip event.
Future<void> callRider(BuildContext context, WidgetRef ref, int tripId) async {
  final l = sgL10n(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final dio = ref.read(dioClientProvider).dio;
  try {
    final r = await dio.post(ApiEndpoints.startTripCall(tripId.toString()));
    final body = r.data is Map ? r.data as Map : const {};
    final data = body['data'] is Map ? body['data'] as Map : body;
    final call = data['call'] is Map ? data['call'] as Map : const {};
    final number = (call['number'] as String?)?.trim();
    final session = call['session_id'];
    if (number == null || number.isEmpty) throw StateError('no bridge number');
    if (session is int) _CallCloser.watch(dio, session);
    final ok = await launchUrl(Uri(scheme: 'tel', path: number));
    if (!ok) messenger?.showSnackBar(SnackBar(content: Text(l.callUnavailable)));
  } on Exception {
    messenger?.showSnackBar(SnackBar(content: Text(l.callUnavailable)));
  } on StateError {
    messenger?.showSnackBar(SnackBar(content: Text(l.callUnavailable)));
  }
}

/// Ends the open call session when the app is resumed (best effort).
class _CallCloser with WidgetsBindingObserver {
  _CallCloser(this.dio, this.session);

  final Dio dio;
  final int session;
  static _CallCloser? _open;

  static void watch(Dio dio, int session) {
    final previous = _open;
    if (previous != null) WidgetsBinding.instance.removeObserver(previous);
    _open = _CallCloser(dio, session);
    WidgetsBinding.instance.addObserver(_open!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    WidgetsBinding.instance.removeObserver(this);
    if (identical(_open, this)) _open = null;
    dio
        .post(ApiEndpoints.endTripCall(session.toString()))
        .then((_) {}, onError: (_) {});
  }
}
