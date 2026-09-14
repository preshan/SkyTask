import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/sky_icon.dart';

/// Hub between notifications and settings: short description + legal links.
class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppInfo.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Version ${AppInfo.versionLabel}',
            textAlign: TextAlign.center,
            style: mist,
          ),
          const SizedBox(height: 16),
          Text(
            'Short description',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(AppInfo.shortDescription, style: mist),
          const SizedBox(height: 20),
          Text(
            'About',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(AppInfo.fullDescription.trim(), style: mist),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SkyIcon(SkyIcons.shield),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How SkyTask handles your data'),
            trailing: const SkyIcon(SkyIcons.chevronRight),
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SkyIcon(SkyIcons.info),
            title: const Text('FAQ'),
            subtitle: const Text('Common questions'),
            trailing: const SkyIcon(SkyIcons.chevronRight),
            onTap: () => context.push(AppRoutes.faq),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SkyIcon(SkyIcons.lock),
            title: const Text('Data safety & permissions'),
            subtitle: const Text('Mic, calendar, alarms, Firebase notes'),
            trailing: const SkyIcon(SkyIcons.chevronRight),
            onTap: () => context.push(AppRoutes.dataSafety),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SkyIcon(SkyIcons.event),
            title: const Text('Open Privacy Policy online'),
            subtitle: const Text(AppInfo.privacyPolicyUrl),
            trailing: const SkyIcon(SkyIcons.chevronRight),
            onTap: () => _open(AppInfo.privacyPolicyUrl),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SkyIcon(SkyIcons.settings),
            title: const Text('Settings'),
            onTap: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}
