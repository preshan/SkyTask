import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../calendar/data/device_calendar_service.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appLock = ref.watch(appLockEnabledProvider);
    final calendarSettings = ref.watch(calendarSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(themeMode)),
            onTap: () => _pickTheme(context, ref, themeMode),
          ),
          const Divider(),
          _header(context, 'Notifications'),
          const SwitchListTile(
            secondary: Icon(Icons.notifications_outlined),
            title: Text('Reminder notifications'),
            subtitle: Text('Local + exact alarms (offline)'),
            value: true,
            onChanged: null,
          ),
          const Divider(),
          _header(context, 'Calendar Sync'),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_month_outlined),
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
              leading: const Icon(Icons.edit_calendar),
              title: const Text('Default calendar'),
              subtitle: Text(calendarSettings.defaultCalendarName ?? 'Not set'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickCalendar(context, ref),
            ),
          const Divider(),
          _header(context, 'Privacy'),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('App lock'),
            subtitle: const Text(
              'Fingerprint, face, or PIN · locks after 30s in background',
            ),
            value: appLock,
            onChanged: (v) =>
                ref.read(privacyLockProvider.notifier).setAppLockEnabled(v),
          ),
          const SwitchListTile(
            secondary: Icon(Icons.shield_outlined),
            title: Text('Private vault'),
            subtitle: Text('Hide private item content'),
            value: true,
            onChanged: null,
          ),
          const Divider(),
          _header(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('SkyTask'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
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
                leading: Icon(
                  DeviceCalendarService.instance.isGoogleCalendar(calendar)
                      ? Icons.event
                      : Icons.calendar_today_outlined,
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
                trailing: current == mode ? const Icon(Icons.check) : null,
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
