import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/content_list_card.dart';
import '../../../../shared/widgets/settings_nav_card.dart';
import '../../../../shared/widgets/sky_icon.dart';

/// Simple scrollable legal / help document.
class LegalDocScreen extends StatelessWidget {
  const LegalDocScreen({
    super.key,
    required this.title,
    required this.sections,
    this.webVersionUrl,
    this.webVersionLabel = 'Web version',
  });

  final String title;
  final List<LegalSection> sections;

  /// Optional public URL shown at the bottom (e.g. Privacy Policy online).
  final String? webVersionUrl;
  final String webVersionLabel;

  Future<void> _openWeb(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.45,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const SkyIcon(SkyIcons.arrowBack),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.settings);
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final section in sections) ...[
            if (section.heading != null ||
                (section.body != null && section.body!.isNotEmpty) ||
                (section.bullets != null && section.bullets!.isNotEmpty)) ...[
              Material(
                color: ContentListCard.surfaceColor(context),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.heading != null) ...[
                        Text(
                          section.heading!,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if ((section.body != null &&
                                section.body!.isNotEmpty) ||
                            (section.bullets != null &&
                                section.bullets!.isNotEmpty))
                          const SizedBox(height: 8),
                      ],
                      if (section.body != null && section.body!.isNotEmpty)
                        Text(section.body!, style: bodyStyle),
                      if (section.bullets != null &&
                          section.bullets!.isNotEmpty) ...[
                        if (section.body != null && section.body!.isNotEmpty)
                          const SizedBox(height: 8),
                        for (final item in section.bullets!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('•  ', style: bodyStyle),
                                Expanded(child: Text(item, style: bodyStyle)),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
          if (webVersionUrl != null)
            SettingsNavCard(
              icon: SkyIcons.link,
              iconColor: const Color(0xFF1E88E5),
              iconBackground: const Color(0xFFE3F2FD),
              title: webVersionLabel,
              subtitle: webVersionUrl,
              onTap: () => _openWeb(webVersionUrl!),
            ),
        ],
      ),
    );
  }
}

class LegalSection {
  const LegalSection({
    this.heading,
    this.body,
    this.bullets,
  });

  final String? heading;
  final String? body;
  final List<String>? bullets;
}
