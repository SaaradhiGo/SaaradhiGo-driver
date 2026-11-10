import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/driver_profile_model.dart';
import '../../../../ui/sg_format.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_text.dart';
import '../../../../ui/sg_tokens.dart';
import '../../../requirements/requirements_api.dart';
import 'display_settings_rows.dart';

/// Profile (10 Nov v2): a summary and six section cards, each with its key details (masked where
/// sensitive), the matching setup step's status, and Edit or Open to that step.

/// "•••• 4821": the last four of whatever mask the server sent.
String lastFourMasked(String? masked, {String gap = ' '}) {
  final digits = (masked ?? '').replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
  if (digits.length < 4) return masked ?? '';
  return '••••$gap${digits.substring(digits.length - 4)}';
}

class ProfileSummary extends ConsumerWidget {
  const ProfileSummary({super.key, required this.profile});
  final DriverProfileModel profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = sgL10n(context);
    final r = ref.watch(requirementsProvider).asData?.value;
    final phone = profile.user?.phoneNumber;
    final rating = profile.ratings;
    final city = (r?.personal['address'] as Json?)?['city'] as String?;
    final approved = r?.approved ?? profile.approved;
    final lines = [
      if (phone != null && phone.isNotEmpty) lastFourMasked(phone),
      l.profRatingTrips(
        (rating == null || rating <= 0) ? l.profNew : rating.toStringAsFixed(1),
        profile.totalTrips ?? 0,
      ),
      if (city != null && city.isNotEmpty) city,
    ];
    return Column(
      key: const Key('profile_summary'),
      children: [
        Text(
          lines.join(' · '),
          textAlign: TextAlign.center,
          style: SgText.small.copyWith(color: SgColors.inkMuted),
        ),
        const SizedBox(height: SgSpace.s2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SgSpace.s3,
            vertical: SgSpace.s1,
          ),
          decoration: BoxDecoration(
            color: approved ? SgStatus.okBg : SgStatus.warnBg,
            borderRadius: BorderRadius.circular(SgRadius.pill),
          ),
          child: Text(
            approved ? l.profApproved : l.profSetupInProgress,
            maxLines: 1,
            softWrap: false,
            style: SgText.small.copyWith(
              fontWeight: FontWeight.w600,
              color: approved ? SgStatus.okInk : SgStatus.warnInk,
            ),
          ),
        ),
      ],
    );
  }
}

/// The six section cards; nothing while the requirements load or fail.
class ProfileSections extends ConsumerWidget {
  const ProfileSections({super.key, required this.profile});
  final DriverProfileModel profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = sgL10n(context);
    final r = ref.watch(requirementsProvider).asData?.value;
    if (r == null) return const SizedBox.shrink();
    final p = r.personal;
    final id = r.identity;
    final pm = r.payoutMethod;
    final dob = DateTime.tryParse('${p['dob']}');
    final city = (p['address'] as Json?)?['city'] as String?;
    final contacts = List<Json>.from(p['emergency_contacts'] as List? ?? []);
    final v = profile.activeVehicleDetails;
    final vehicle = v == null
        ? null
        : [
            '${v['brand'] ?? ''} ${v['model'] ?? ''}'.trim(),
            '${v['vehicle_number'] ?? ''}',
          ].where((s) => s.isNotEmpty).join(' · ');
    final bank = pm['bank'] as Json?;
    final payout = r.country == 'US'
        ? (pm['stripe_status'] == 'ready' ? l.profStripeReady : null)
        : bank != null
        ? '${bank['bank_name']} ${lastFourMasked('${bank['account_masked']}', gap: '')}'
        : pm['upi_masked'] != null
        ? 'UPI ${pm['upi_masked']}'
        : null;
    final language = switch (l.localeName) {
      'te' => l.languageTelugu,
      'hi' => l.languageHindi,
      _ => l.languageEnglish,
    };

    final sections = <(String, String, String?, List<String>)>[
      (
        'personal',
        l.profSecPersonal,
        'personal',
        [
          if ('${p['full_name'] ?? ''}'.isNotEmpty) '${p['full_name']}',
          if (dob != null) sgMarketDate(dob, r.country),
          ?city,
        ],
      ),
      (
        'contact',
        l.profSecContacts,
        'contact',
        [for (final c in contacts) '${c['name']}'],
      ),
      (
        'identity',
        l.profSecIdentity,
        'identity',
        [
          if ('${id['license_number'] ?? ''}'.isNotEmpty)
            l.profLicence('${id['license_number']}'),
          if (id['aadhaar_masked'] != null)
            l.profAadhaar(lastFourMasked('${id['aadhaar_masked']}')),
          if (id['pan_masked'] != null) l.profPan('${id['pan_masked']}'),
        ],
      ),
      ('vehicle', l.profSecVehicle, 'vehicle', [?vehicle]),
      ('payouts', l.profSecBank, 'payouts', [?payout]),
      ('language', l.profSecLanguage, null, [language]),
    ];

    return Column(
      key: const Key('profile_sections'),
      children: [
        for (final (key, title, stepKey, details) in sections)
          if (stepKey == null || r.step(stepKey) != null)
            _SectionCard(
              key: Key('profile_section_$key'),
              title: title,
              details: details.isEmpty ? [l.profNotAdded] : details,
              step: stepKey == null ? null : r.step(stepKey),
              onOpen: stepKey == null
                  ? () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => const SafeArea(
                        child: Padding(
                          padding: EdgeInsets.all(SgSpace.s4),
                          child: DisplaySettingsRows(),
                        ),
                      ),
                    )
                  : () => context.push('/onboarding/step/$stepKey'),
            ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.details,
    required this.step,
    required this.onOpen,
  });
  final String title;
  final List<String> details;
  final SetupStep? step;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final status = step?.status;
    final (String? pill, Color ink, Color bg) = switch (status) {
      'done' => (l.reqStatusDone, SgStatus.okInk, SgStatus.okBg),
      'in_review' => (l.reqStatusInReview, SgStatus.warnInk, SgStatus.warnBg),
      'action' => (
        l.setupNeedsAction,
        SgColors.danger,
        SgColors.tint(SgColors.danger),
      ),
      'todo' => (l.setupToDo, SgColors.inkMuted, SgStatus.rowFill),
      _ => (null, SgColors.inkMuted, SgStatus.rowFill),
    };
    final edit = status == null || status == 'done' || status == 'in_review';
    return Container(
      margin: const EdgeInsets.only(bottom: SgSpace.s2),
      padding: const EdgeInsets.all(SgSpace.s3),
      decoration: BoxDecoration(
        color: SgColors.bg100,
        borderRadius: BorderRadius.circular(SgRadius.md),
        border: Border.all(color: SgColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: SgText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (pill != null) ...[
                      const SizedBox(width: SgSpace.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SgSpace.s2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(SgRadius.pill),
                        ),
                        child: Text(
                          pill,
                          maxLines: 1,
                          softWrap: false,
                          style: SgText.small.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                for (final d in details)
                  Text(
                    d,
                    style: SgText.small.copyWith(color: SgColors.inkMuted),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onOpen,
            child: Text(edit ? l.profEdit : l.profOpen),
          ),
        ],
      ),
    );
  }
}
