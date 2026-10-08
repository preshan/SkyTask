import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/about_brand_card.dart';
import '../../../../shared/widgets/content_list_card.dart';
import '../../../../shared/widgets/settings_nav_card.dart';
import '../../../../shared/widgets/sky_icon.dart';

/// Hub between notifications and settings: app info + legal links.
class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mist = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          height: 1.4,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('About & help'),
        leading: IconButton(
          icon: const SkyIcon(SkyIcons.arrowBack),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const AboutBrandCard(showDescription: true),
          const SizedBox(height: 20),
          Material(
            color: ContentListCard.surfaceColor(context),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What you can do',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tasks, reminders, ideas, and notes in one place. Content '
                    'stays on your phone by default.',
                    style: mist,
                  ),
                  const SizedBox(height: 12),
                  const _Bullet(
                    'Tasks with priorities, categories, due dates, and Day Plan',
                  ),
                  const _Bullet(
                    'Reminders with local notifications and optional calendar sync',
                  ),
                  const _Bullet(
                    'Ideas and notes, including private items behind app lock',
                  ),
                  const _Bullet(
                    'Voice memos you can record, play, pause, and seek',
                  ),
                  const _Bullet(
                    'Local storage with optional backup export and import',
                  ),
                  const _Bullet('Light and dark themes'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SettingsNavCard(
            icon: SkyIcons.shield,
            iconColor: const Color(0xFF43A047),
            iconBackground: const Color(0xFFE8F5E9),
            title: 'Privacy Policy',
            subtitle: 'How SkyTask handles your data',
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          const SizedBox(height: 10),
          SettingsNavCard(
            icon: SkyIcons.note,
            iconColor: const Color(0xFFFB8C00),
            iconBackground: const Color(0xFFFFF3E0),
            title: 'FAQ',
            subtitle: 'Common questions',
            onTap: () => context.push(AppRoutes.faq),
          ),
          const SizedBox(height: 10),
          SettingsNavCard(
            icon: SkyIcons.lightbulb,
            iconColor: const Color(0xFF8E24AA),
            iconBackground: const Color(0xFFF3E5F5),
            title: 'Data safety & permissions',
            subtitle: 'Mic, calendar, alarms, and account notes',
            onTap: () => context.push(AppRoutes.dataSafety),
          ),
          const SizedBox(height: 10),
          SettingsNavCard(
            icon: SkyIcons.settings,
            iconColor: const Color(0xFF5C6BC0),
            iconBackground: const Color(0xFFE8EAF6),
            title: 'Settings',
            subtitle: 'Theme, sync, privacy, and backups',
            onTap: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          height: 1.4,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: style),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
