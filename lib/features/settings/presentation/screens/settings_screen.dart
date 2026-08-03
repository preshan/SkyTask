import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../calendar/data/device_calendar_service.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appLock = ref.watch(appLockEnabledProvider);
    final calendarSettings = ref.watch(calendarSettingsProvider);
    final mist = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
        children: [
          _header(context, 'Appearance'),
          ListTile(
            leading: const SkyIcon(SkyIcons.palette),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(themeMode)),
            onTap: () => _pickTheme(context, ref, themeMode),
          ),
          const Divider(),
          _header(context, 'Notifications'),
          const SwitchListTile(
            secondary: SkyIcon(SkyIcons.notification),
            title: Text('Reminder notifications'),
            subtitle: Text('Local + exact alarms (offline)'),
            value: true,
            onChanged: null,
          ),
          const Divider(),
          _header(context, 'Calendar Sync'),
          SwitchListTile(
            secondary: const SkyIcon(SkyIcons.calendar),
            title: const Text('Google Calendar sync'),
            subtitle: Text(
              calendarSettings.syncEnabled
                  ? calendarSettings.isGoogleCalendar
                      ? 'Reminders sync to Google: ${calendarSettings.defaultCalendarName}'
                      : 'Reminders sync to ${calendarSettings.defaultCalendarName}'
                  : 'Write SkyTask reminders to your Google Calendar',
            ),
            value: calendarSettings.syncEnabled,
            onChanged: (enabled) async {
              final ok = await ref
                  .read(calendarSettingsProvider.notifier)
                  .setSyncEnabled(enabled);
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Could not enable sync. Add a Google account in Android Settings, grant calendar permission, then try again.',
                    ),
                  ),
                );
              } else {
                refreshReminders(ref);
              }
            },
          ),
          if (calendarSettings.syncEnabled)
            ListTile(
              leading: const SkyIcon(SkyIcons.edit),
              title: const Text('Default calendar'),
              subtitle: Text(calendarSettings.defaultCalendarName ?? 'Not set'),
              trailing: const SkyIcon(SkyIcons.chevronRight),
              onTap: () => _pickCalendar(context, ref),
            ),
          const Divider(),
          _header(context, 'Privacy'),
          SwitchListTile(
            secondary: const SkyIcon(SkyIcons.lock),
            title: const Text('App lock'),
            subtitle: const Text(
              'Fingerprint, face, or PIN · locks after 30s in background',
            ),
            value: appLock,
            onChanged: (v) =>
                ref.read(privacyLockProvider.notifier).setAppLockEnabled(v),
          ),
          const SwitchListTile(
            secondary: SkyIcon(SkyIcons.shield),
            title: Text('Private vault'),
            subtitle: Text('Hide private item content'),
            value: true,
            onChanged: null,
          ),
          const Divider(),
          _header(context, 'About'),
          ListTile(
            leading: const SkyIcon(SkyIcons.info),
            title: const Text(AppInfo.name),
            subtitle: Text('Version ${AppInfo.versionLabel}'),
            onTap: () => _showAbout(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              children: [
                Text(
                  AppInfo.copyright,
                  style: mist,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Developed by ${AppInfo.developerName}',
                  style: mist,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _ContactLink(
                  icon: SkyIcons.linkedIn,
                  label: 'LinkedIn',
                  onTap: () => _openLink(AppInfo.developerLinkedIn),
                ),
                const SizedBox(height: 6),
                _ContactLink(
                  icon: SkyIcons.mail,
                  label: AppInfo.developerEmail,
                  onTap: () =>
                      _openLink('mailto:${AppInfo.developerEmail}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: AppInfo.versionLabel,
      applicationLegalese: AppInfo.copyright,
      children: [
        const SizedBox(height: 12),
        Text(AppInfo.tagline),
        const SizedBox(height: 8),
        Text('Developed by ${AppInfo.developerName}'),
        Text(AppInfo.developerEmail),
      ],
    );
  }

  Future<void> _pickCalendar(BuildContext context, WidgetRef ref) async {
    final calendars =
        await DeviceCalendarService.instance.getWritableCalendars();
    if (!context.mounted) return;
    if (calendars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No writable calendars found')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choose Google / device calendar'),
            ),
            for (final calendar in calendars)
              ListTile(
                leading: SkyIcon(
                  DeviceCalendarService.instance.isGoogleCalendar(calendar)
                      ? SkyIcons.event
                      : SkyIcons.today,
                ),
                title: Text(calendar.name ?? 'Unnamed calendar'),
                subtitle: Text(
                  [
                    calendar.accountName ?? 'Local account',
                    if (DeviceCalendarService.instance.isGoogleCalendar(calendar))
                      'Google Calendar',
                  ].join(' • '),
                ),
                onTap: () async {
                  final isGoogle =
                      DeviceCalendarService.instance.isGoogleCalendar(calendar);
                  await ref
                      .read(calendarSettingsProvider.notifier)
                      .setDefaultCalendar(
                        id: calendar.id!,
                        name: calendar.name ?? 'Calendar',
                        isGoogleCalendar: isGoogle,
                      );
                  refreshReminders(ref);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System default',
      };

  void _pickTheme(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              ListTile(
                title: Text(_themeLabel(mode)),
                trailing: current == mode
                    ? const SkyIcon(SkyIcons.check)
                    : null,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactLink extends StatelessWidget {
  const _ContactLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkyIcon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
