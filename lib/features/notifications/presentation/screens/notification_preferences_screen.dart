import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/notification_prefs.dart';
import '../providers/notification_preferences_provider.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

const String kPrefsSaveFailed =
    "We couldn't save that change. Your setting has not changed.";

const Map<String, String> _channelNames = {
  'in_app': 'In the app',
  'push': 'Push notifications',
  'sms': 'SMS',
  'email': 'Email',
};

/// Notification preferences (D5): GET and PUT /notifications/preferences/.
///
/// Consent rules, enforced here as well as by the API:
/// * nothing is saved on opening the screen; a row is written only when the
///   driver flips its switch;
/// * offers (promotional) and WhatsApp are never pre-ticked: the switch shows
///   what the API says, and the API's default for both is off;
/// * trip and account updates in the app and by push are shown fixed on, with
///   a disabled switch and a one-line reason.
class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  NotificationPrefs? _prefs;
  bool _loading = true;
  bool _failed = false;
  String? _error;
  final Set<PrefKey> _saving = {};

  NotificationPreferencesService get _service =>
      ref.read(notificationPreferencesServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final prefs = await _service.fetch();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _failed = prefs == null;
      _loading = false;
    });
  }

  /// Optimistic: the switch moves at once, the PUT follows, and a failure puts
  /// the switch back and says so.
  Future<void> _toggle(String channel, String category, bool value) async {
    final before = _prefs;
    if (before == null) return;
    final key = PrefKey(channel, category);
    if (_saving.contains(key)) return;
    setState(() {
      _error = null;
      _saving.add(key);
      _prefs = before.withValue(channel, category, value);
    });
    final saved = await _service.save(
      channel: channel,
      category: category,
      optedIn: value,
    );
    if (!mounted) return;
    setState(() {
      _saving.remove(key);
      if (saved != null) {
        _prefs = saved;
      } else {
        _prefs = _prefs?.withValue(
          channel,
          category,
          before.value(channel, category),
        );
        _error = kPrefsSaveFailed;
      }
    });
  }

  Widget _row({
    required String channel,
    required String category,
    required String title,
    required String subtitle,
    required bool fixed,
  }) {
    final saving = _saving.contains(PrefKey(channel, category));
    return SwitchListTile(
      key: Key('pref_${channel}_$category'),
      activeThumbColor: AppColors.darkText,
      activeTrackColor: AppColors.primary,
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(
          color: fixed ? AppColors.secondaryGray : AppColors.onBackground,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
          fontSize: SgText.size(13),
        ),
      ),
      value: _prefs!.value(channel, category),
      onChanged: fixed || saving ? null : (v) => _toggle(channel, category, v),
    );
  }

  Widget _section(String heading, String? note, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              heading,
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
              ),
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                note,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: SgText.size(13),
                ),
              ),
            ),
          ...rows,
        ],
      ),
    );
  }

  List<Widget> _body(NotificationPrefs prefs) {
    final transactional = <Widget>[
      for (final channel in const ['in_app', 'push'])
        if (prefs.has(channel, kTransactional))
          _row(
            channel: channel,
            category: kTransactional,
            title: _channelNames[channel]!,
            subtitle: 'Always on. Needed for your trips and your safety.',
            fixed: true,
          ),
    ];
    final promotional = <Widget>[
      for (final channel in const ['push', 'sms', 'email', 'in_app'])
        if (prefs.has(channel, kPromotional))
          _row(
            channel: channel,
            category: kPromotional,
            title: _channelNames[channel]!,
            subtitle: 'Off unless you turn it on.',
            fixed: prefs.isLocked(channel, kPromotional),
          ),
    ];
    final whatsapp = <Widget>[
      if (prefs.has('whatsapp', kTransactional))
        _row(
          channel: 'whatsapp',
          category: kTransactional,
          title: 'Trip updates on WhatsApp',
          subtitle: 'Off unless you turn it on.',
          fixed: prefs.isLocked('whatsapp', kTransactional),
        ),
      if (prefs.has('whatsapp', kPromotional))
        _row(
          channel: 'whatsapp',
          category: kPromotional,
          title: 'Offers on WhatsApp',
          subtitle: 'Off unless you turn it on.',
          fixed: prefs.isLocked('whatsapp', kPromotional),
        ),
    ];
    return [
      if (_error != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            _error!,
            key: const Key('prefs_error'),
            style: AppTypography.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
      if (transactional.isNotEmpty)
        _section('Trip and account updates', null, transactional),
      if (promotional.isNotEmpty)
        _section(
          'Offers and news',
          'Choose where you would like to hear about offers. '
              'You can change this at any time.',
          promotional,
        ),
      if (whatsapp.isNotEmpty) _section('WhatsApp', null, whatsapp),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notification preferences',
          style: AppTypography.headlineSm.copyWith(color: AppColors.primaryText),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primaryText),
              )
            : _failed
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "We couldn't load your notification preferences.",
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        key: const Key('prefs_retry'),
                        onPressed: _load,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(children: _body(_prefs!)),
      ),
    );
  }
}
