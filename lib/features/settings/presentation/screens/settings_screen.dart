import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../backup/data/backup_folder_service.dart';
import '../../../backup/presentation/backup_dialogs.dart';
import '../../../calendar/data/device_calendar_service.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../privacy/data/pin_storage_service.dart';
import '../../../privacy/data/privacy_auth_service.dart';

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
              final result = await ref
                  .read(calendarSettingsProvider.notifier)
                  .setSyncEnabled(enabled);
              if (!context.mounted) return;
              if (!result.success) {
                final message = switch (result.failure) {
                  CalendarSyncFailure.permanentlyDenied =>
                    'Calendar permission is blocked. Allow it in system Settings.',
                  CalendarSyncFailure.permissionDenied =>
                    'Calendar permission is required to sync reminders.',
                  CalendarSyncFailure.noCalendars =>
                    'No writable calendars found. Open the Calendar app once, or check Google account calendar sync in Android Settings.',
                  null => 'Could not enable calendar sync.',
                };
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    action: result.failure ==
                            CalendarSyncFailure.permanentlyDenied
                        ? SnackBarAction(
                            label: 'Settings',
                            onPressed: openAppSettings,
                          )
                        : null,
                  ),
                );
              } else if (enabled) {
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
            onChanged: (v) => _onAppLockChanged(context, ref, v),
          ),
          if (appLock &&
              (ref.watch(biometricsAvailableProvider).valueOrNull ?? false))
            SwitchListTile(
              secondary: const SkyIcon(SkyIcons.fingerprint),
              title: const Text('Unlock with fingerprint'),
              subtitle: Text(
                ref.watch(unlockAuthMethodProvider).valueOrNull ==
                        AuthMethod.biometric
                    ? 'Fingerprint or face · PIN still works as backup'
                    : 'Use fingerprint instead of typing your PIN each time',
              ),
              value: ref.watch(unlockAuthMethodProvider).valueOrNull ==
                  AuthMethod.biometric,
              onChanged: (v) => _onFingerprintUnlockChanged(context, ref, v),
            ),
          const Divider(),
          _header(context, 'Data'),
          ListTile(
            leading: const SkyIcon(SkyIcons.folder),
            title: const Text('Backup folder'),
            subtitle: Text(
              BackupFolderService.instance.displayLabel(
                ref.watch(backupFolderPathProvider),
              ),
            ),
            trailing: const SkyIcon(SkyIcons.chevronRight),
            onTap: () => showPickBackupFolderFlow(context, ref),
          ),
          ListTile(
            leading: const SkyIcon(SkyIcons.archive),
            title: const Text('Export backup'),
            subtitle: const Text('Compressed file · optional password'),
            onTap: () => showExportBackupFlow(context, ref),
          ),
          ListTile(
            leading: const SkyIcon(SkyIcons.note),
            title: const Text('Import backup'),
            subtitle: const Text('From Files or shared storage'),
            onTap: () => showImportBackupFlow(context, ref),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              children: [
                InkWell(
                  onTap: () => _showAbout(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppInfo.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version ${AppInfo.versionLabel}',
                          style: mist,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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

  Future<void> _onAppLockChanged(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final lock = ref.read(privacyLockProvider.notifier);
    if (!enabled) {
      // Turning lock off must prove identity — unlocked session alone is not enough.
      final method = await PinStorageService.instance.getAuthMethod();
      var ok = false;
      try {
        if (method == AuthMethod.pin) {
          if (!context.mounted) return;
          ok = await _confirmPinDialog(context) ?? false;
        } else {
          ok = await PrivacyAuthService.instance.authenticateWithBiometrics(
            reason: 'Confirm to turn off app lock',
          );
        }
      } catch (_) {
        ok = false;
      }
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not verify — app lock stays on')),
        );
        return;
      }
    }

    await ref.read(appLockEnabledProvider.notifier).setEnabled(enabled);
    if (enabled) {
      // Defer so SwitchListTile finishes its rebuild before lock overlays.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        lock.lock();
      });
    } else {
      lock.unlock();
    }
  }

  Future<void> _onFingerprintUnlockChanged(
    BuildContext context,
    WidgetRef ref,
    bool enableFingerprint,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (enableFingerprint) {
      final hasPin = await PinStorageService.instance.hasPin();
      if (!hasPin) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Set a PIN first, then turn on fingerprint unlock'),
          ),
        );
        return;
      }
      if (!context.mounted) return;
      final pinOk = await _confirmPinDialog(context) ?? false;
      if (!pinOk) {
        messenger.showSnackBar(
          const SnackBar(content: Text('PIN required to enable fingerprint')),
        );
        return;
      }
      final bioOk =
          await PrivacyAuthService.instance.authenticateWithBiometrics(
        reason: 'Confirm fingerprint to unlock SkyTask',
      );
      if (!bioOk) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Fingerprint confirmation failed')),
        );
        return;
      }
      await PinStorageService.instance.setBiometricMethod();
      ref.invalidate(unlockAuthMethodProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Fingerprint unlock on · PIN still works as backup'),
        ),
      );
      return;
    }

    // Turn fingerprint preference off → unlock with PIN again.
    final ok = await PrivacyAuthService.instance.authenticateWithBiometrics(
      reason: 'Confirm to switch back to PIN unlock',
    );
    if (!ok) {
      if (!context.mounted) return;
      final pinOk = await _confirmPinDialog(context) ?? false;
      if (!pinOk) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not verify — staying on fingerprint')),
        );
        return;
      }
    }
    await PinStorageService.instance.setPinMethod();
    ref.invalidate(unlockAuthMethodProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('PIN unlock restored')),
    );
  }

  Future<bool?> _confirmPinDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const _ConfirmPinDialog(),
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

class _ConfirmPinDialog extends StatefulWidget {
  const _ConfirmPinDialog();

  @override
  State<_ConfirmPinDialog> createState() => _ConfirmPinDialogState();
}

class _ConfirmPinDialogState extends State<_ConfirmPinDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final ok =
        await PrivacyAuthService.instance.verifyPin(_controller.text.trim());
    if (mounted) Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter PIN'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
        autofocus: true,
        decoration: const InputDecoration(hintText: '4-digit PIN'),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
