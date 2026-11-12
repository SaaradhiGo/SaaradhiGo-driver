import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/market/market_providers.dart';
import '../../core/network/environment_config.dart';
import '../../ui/sg_text.dart';
import '../../ui/sg_tokens.dart';
import 'legal_entity.dart';

const String kProductionSite = 'https://www.saaradhigo.com';
const String kQaSite = 'https://www.qa.saaradhigo.com';

/// The public pages, on the website. The QA host in a QA build.
String siteHost() => EnvironmentConfig.environmentLabel == 'non-production'
    ? kQaSite
    : kProductionSite;

class PolicyLink {
  const PolicyLink(this.label, this.path, {this.indiaOnly = false});
  final String label;
  final String path;
  final bool indiaOnly;

  Uri uri([String? host]) => Uri.parse('${host ?? siteHost()}$path');
}

/// What a driver can open from About, in order. Driver terms, not rider terms.
const List<PolicyLink> kDriverPolicyLinks = <PolicyLink>[
  PolicyLink('About SaaradhiGo', '/about'),
  PolicyLink('Contact us', '/contact'),
  PolicyLink('Fares', '/fares'),
  PolicyLink('Driver terms', '/driver-terms'),
  PolicyLink('Privacy policy', '/privacy'),
  PolicyLink('Refunds and cancellations', '/refunds'),
  PolicyLink('Text messages', '/text-messages'),
  PolicyLink('Grievance redressal', '/grievance', indiaOnly: true),
  PolicyLink('Cookies', '/cookies'),
  PolicyLink('Safety', '/safety'),
];

List<PolicyLink> policyLinksFor(String? countryCode) => [
  for (final l in kDriverPolicyLinks)
    if (!l.indiaOnly || (countryCode ?? 'IN').toUpperCase() == 'IN') l,
];

Future<void> openPolicy(PolicyLink link) =>
    launchUrl(link.uri(), mode: LaunchMode.externalApplication);

/// About: the operator of the service for the driver's market, the app
/// version and the links to the public pages. Nothing is shown that the server
/// did not send, except the operator's name.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key, this.year, this.versionLoader});

  /// Test seams: the year for the copyright line and the version lookup.
  final int? year;
  final Future<String?> Function()? versionLoader;

  static Future<String?> _version() async {
    try {
      final i = await PackageInfo.fromPlatform();
      return '${i.version} (${i.buildNumber})';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final country = ref.watch(marketConfigProvider).countryCode;
    final entity =
        ref.watch(legalEntityProvider).asData?.value ??
        LegalEntity.fallback(country);
    return Scaffold(
      backgroundColor: SgColors.bg000,
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          key: const Key('about_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(SgSpace.s5),
        children: [
          Text('SaaradhiGo Driver', style: SgText.heading),
          const SizedBox(height: SgSpace.s2),
          FutureBuilder<String?>(
            future: (versionLoader ?? _version)(),
            builder: (c, snap) => (snap.data ?? '').isEmpty
                ? const SizedBox.shrink()
                : Text('Version ${snap.data}', style: SgText.small),
          ),
          const SizedBox(height: SgSpace.s4),
          Text(
            entity.copyright(year ?? DateTime.now().year),
            key: const Key('about_operator'),
            style: SgText.body,
          ),
          for (final line in [
            entity.registeredAddress,
            if (entity.cin.isNotEmpty) 'CIN ${entity.cin}',
            if (entity.gstRegistered && entity.gstin.isNotEmpty)
              'GSTIN ${entity.gstin}',
            entity.supportPhone,
            entity.supportEmail,
          ])
            if (line.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: SgSpace.s1),
                child: Text(line, style: SgText.small),
              ),
          const SizedBox(height: SgSpace.s6),
          Text('POLICIES AND INFORMATION', style: SgText.eyebrow),
          const SizedBox(height: SgSpace.s2),
          for (final link in policyLinksFor(country))
            InkWell(
              key: Key('about_link_${link.path.substring(1)}'),
              onTap: () => openPolicy(link),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(child: Text(link.label, style: SgText.body)),
                    Icon(Icons.open_in_new, size: 16, color: SgColors.inkMuted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
