import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/dio_client.dart';
import '../../../ui/sg_format.dart';
import '../../../ui/sg_text.dart';
import '../../../ui/sg_tokens.dart';
import '../../../ui/sg_widgets.dart';
import '../../about/about_screen.dart';
import '../../auth/presentation/providers/auth_notifier.dart';

/// Profile > Delete account (Play Store policy). The server says what is
/// deleted and what it must keep; the app shows those sentences as written.
/// While the server has not shipped the endpoint (404) fixed text stands in.

typedef Json = Map<String, dynamic>;

const List<String> kFallbackDeleted = [
  'Your profile, photo and contact details.',
  'Your documents and bank or UPI details.',
  'Your sign-in on this and every other device.',
];
const List<String> kFallbackKept = [
  'Trips, payouts and tax records, kept for their legal periods.',
];

class PendingPayouts {
  PendingPayouts.fromJson(Json j)
    : balance = '${j['balance'] ?? '0'}',
      currency = (j['currency'] as String?) ?? 'INR',
      inFlight = (j['in_flight'] as num?)?.toInt() ?? 0;
  final String balance, currency;
  final int inFlight;

  /// Anything still owed to the driver, or on its way to them.
  bool get owed => (double.tryParse(balance) ?? 0) > 0 || inFlight > 0;
}

class DeleteInfo {
  const DeleteInfo({
    required this.deleted,
    required this.kept,
    this.pending,
    this.closing = false,
    this.webUrl,
  });

  factory DeleteInfo.fallback() =>
      const DeleteInfo(deleted: kFallbackDeleted, kept: kFallbackKept);

  factory DeleteInfo.fromJson(Json j) {
    List<String> strings(Object? v, List<String> fallback) {
      final l = [
        if (v is List)
          for (final s in v)
            if ('$s'.trim().isNotEmpty) '$s',
      ];
      return l.isEmpty ? fallback : l;
    }

    final p = j['pending_payouts'];
    return DeleteInfo(
      deleted: strings(j['deleted'], kFallbackDeleted),
      kept: strings(j['kept'], kFallbackKept),
      pending: p is Map ? PendingPayouts.fromJson(Json.from(p)) : null,
      closing: j['closure'] is Map,
      webUrl: j['web_url'] as String?,
    );
  }

  final List<String> deleted, kept;
  final PendingPayouts? pending;

  /// The server's closure is set: waiting for earnings to be paid.
  final bool closing;
  final String? webUrl;
}

class DeleteResult {
  const DeleteResult({required this.closed, required this.message});
  final bool closed;
  final String message;
}

class DeleteAccountApi {
  DeleteAccountApi(this.dio);
  final Dio dio;

  static Json _data(Response<dynamic> r) {
    final body = r.data;
    if (body is Map && body['data'] is Map) {
      return Json.from(body['data'] as Map);
    }
    return body is Map ? Json.from(body) : <String, dynamic>{};
  }

  Future<DeleteInfo> info() async {
    try {
      return DeleteInfo.fromJson(_data(await dio.get('/auth/me/delete/')));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return DeleteInfo.fallback();
      rethrow;
    }
  }

  /// 200 closed, 202 waiting for payouts; anything else throws.
  Future<DeleteResult> delete(String reason) async {
    final r = await dio.post(
      '/auth/me/delete/',
      data: {'confirm': 'DELETE', 'reason': reason},
      options: Options(validateStatus: (s) => s != null && s < 300),
    );
    final d = _data(r);
    return DeleteResult(
      closed: r.statusCode == 200 && d['status'] != 'waiting_payouts',
      message: (d['message'] as String?) ?? '',
    );
  }
}

final deleteAccountApiProvider = Provider<DeleteAccountApi>(
  (ref) => DeleteAccountApi(ref.watch(dioClientProvider).dio),
);

final deleteInfoProvider = FutureProvider.autoDispose<DeleteInfo>(
  (ref) => ref.watch(deleteAccountApiProvider).info(),
);

/// `/profile/delete`.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _closingMessage;

  @override
  void dispose() {
    _confirm.dispose();
    _reason.dispose();
    super.dispose();
  }

  bool get _typed => _confirm.text.trim().toUpperCase() == 'DELETE';

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(deleteAccountApiProvider)
          .delete(_reason.text.trim());
      if (!mounted) return;
      if (res.closed) {
        // Signing out sends the router to the start screen.
        await ref.read(authNotifierProvider.notifier).logout();
        return;
      }
      setState(() {
        _busy = false;
        _closingMessage = res.message.isEmpty
            ? 'Your account closes after your earnings are paid.'
            : res.message;
      });
      ref.invalidate(deleteInfoProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not delete your account. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(deleteInfoProvider);
    return Scaffold(
      backgroundColor: SgColors.bg000,
      appBar: AppBar(title: const Text('Delete account')),
      body: SafeArea(
        child: info.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: SgColors.gold500)),
          error: (_, _) => ListView(
            padding: const EdgeInsets.all(SgSpace.s5),
            children: [
              Text(
                'Could not load this page',
                textAlign: TextAlign.center,
                style: SgText.title,
              ),
              const SizedBox(height: SgSpace.s4),
              SgPrimaryButton(
                label: 'Try again',
                onPressed: () => ref.invalidate(deleteInfoProvider),
              ),
            ],
          ),
          data: _body,
        ),
      ),
    );
  }

  Widget _section(String title, List<String> lines) => Padding(
    padding: const EdgeInsets.only(bottom: SgSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: SgText.title),
        const SizedBox(height: SgSpace.s2),
        for (final s in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: SgSpace.s1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: SgText.body),
                Expanded(child: Text(s, style: SgText.body)),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _body(DeleteInfo info) {
    final p = info.pending;
    final closing = info.closing || _closingMessage != null;
    final webUrl = '${siteHost()}/delete-account';
    final owedText = p == null || !p.owed
        ? null
        : 'We still owe you ${sgMoney2(p.balance, currency: p.currency) ?? p.balance}'
              '${p.inFlight > 0 ? ' (${p.inFlight} payout${p.inFlight == 1 ? '' : 's'} on the way)' : ''}. '
              'Your account closes after your earnings are paid.';
    return ListView(
      key: const Key('delete_list'),
      padding: const EdgeInsets.all(SgSpace.s4),
      children: [
        _section('What is deleted', info.deleted),
        _section('What we must keep', info.kept),
        if (owedText != null)
          Container(
            key: const Key('delete_owed'),
            margin: const EdgeInsets.only(bottom: SgSpace.s4),
            padding: const EdgeInsets.all(SgSpace.s3),
            decoration: BoxDecoration(
              color: SgColors.bg100,
              borderRadius: BorderRadius.circular(SgRadius.md),
              border: Border.all(color: SgColors.goldLine),
            ),
            child: Text(owedText, style: SgText.body),
          ),
        if (closing)
          Container(
            key: const Key('delete_closing'),
            padding: const EdgeInsets.all(SgSpace.s3),
            decoration: BoxDecoration(
              color: SgColors.bg100,
              borderRadius: BorderRadius.circular(SgRadius.md),
              border: Border.all(color: SgColors.goldLine),
            ),
            child: Text(
              _closingMessage ??
                  'Closing: waiting for your earnings to be paid',
              style: SgText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          )
        else ...[
          TextField(
            key: const Key('delete_reason'),
            controller: _reason,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Why are you leaving? (optional)',
            ),
          ),
          const SizedBox(height: SgSpace.s3),
          TextField(
            key: const Key('delete_confirm_field'),
            controller: _confirm,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Type DELETE to confirm',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: SgSpace.s2),
            Text(_error!, style: SgText.small.copyWith(color: SgColors.danger)),
          ],
          const SizedBox(height: SgSpace.s4),
          SgPrimaryButton(
            key: const Key('delete_submit'),
            label: _busy ? 'Please wait' : 'Delete my account',
            onPressed: _typed && !_busy ? _submit : null,
          ),
        ],
        const SizedBox(height: SgSpace.s5),
        InkWell(
          key: const Key('delete_web_link'),
          onTap: () => launchUrl(
            Uri.parse(webUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            'You can also delete your account without the app: $webUrl',
            style: SgText.small.copyWith(color: SgColors.goldText),
          ),
        ),
      ],
    );
  }
}
