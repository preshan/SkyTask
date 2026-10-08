import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_info.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/about_brand_card.dart';
import '../../../../shared/widgets/settings_nav_card.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _SectionLabel('Appearance'),
          SettingsNavCard(
            icon: SkyIcons.palette,
            iconColor: const Color(0xFF5C6BC0),
            iconBackground: const Color(0xFFE8EAF6),
            title: 'Theme',
            subtitle: _themeLabel(themeMode),
            onTap: () => _pickTheme(context, ref, themeMode),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Notifications'),
          const SettingsSwitchCard(
            icon: SkyIcons.notification,
            iconColor: Color(0xFF1E88E5),
            iconBackground: Color(0xFFE3F2FD),
            title: 'Reminder notifications',
            subtitle: 'Local + exact alarms (offline)',
            value: true,
            onChanged: null,
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Calendar Sync'),
          SettingsSwitchCard(
            icon: SkyIcons.calendar,
            iconColor: const Color(0xFF00897B),
            iconBackground: const Color(0xFFE0F2F1),
            title: 'Calendar sync',
            subtitle: calendarSettings.syncEnabled
                ? calendarSettings.isGoogleCalendar
                    ? 'Reminders sync to Google: ${calendarSettings.defaultCalendarName}'
                    : 'Reminders sync to ${calendarSettings.defaultCalendarName}'
                : 'Write reminders to a device calendar (Google if available)',
            value: calendarSettings.syncEnabled,
            onChanged: (enabled) async {
              final result = await ref
                  .read(calendarSettingsProvider.notifier)
                  .setSyncEnabled(enabled);
              if (!context.mounted) return;
              if (!result.success) {
                final message = switch (result.failure) {
                  CalendarSyncFailure.permanentlyDenied =>
                    'Calendar permission is blocked. Allow Calendar (read & write) in system Settings.',
                  CalendarSyncFailure.permissionDenied =>
                    'Calendar read & write permission is required to sync reminders.',
                  CalendarSyncFailure.noCalendars =>
                    'No writable calendar found. Add a Google account (Settings → Accounts), open the Calendar app once, then try again. SkyTask can also create a local calendar if Calendar permission is allowed.',
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
          if (calendarSettings.syncEnabled) ...[
            const SizedBox(height: 10),
            SettingsNavCard(
              icon: SkyIcons.edit,
              iconColor: const Color(0xFF00897B),
              iconBackground: const Color(0xFFE0F2F1),
              title: 'Default calendar',
              subtitle: calendarSettings.defaultCalendarName ?? 'Not set',
              onTap: () => _pickCalendar(context, ref),
            ),
          ],
          const SizedBox(height: 16),
          const _SectionLabel('Privacy'),
          SettingsSwitchCard(
            icon: SkyIcons.lock,
            iconColor: const Color(0xFF6A1B9A),
            iconBackground: const Color(0xFFF3E5F5),
            title: 'App lock',
            subtitle:
                'Fingerprint, face, or PIN · locks after 30s in background',
            value: appLock,
            onChanged: (v) => _onAppLockChanged(context, ref, v),
          ),
          if (appLock &&
              (ref.watch(biometricsAvailableProvider).valueOrNull ?? false)) ...[
            const SizedBox(height: 10),
            SettingsSwitchCard(
              icon: SkyIcons.fingerprint,
              iconColor: const Color(0xFF6A1B9A),
              iconBackground: const Color(0xFFF3E5F5),
              title: 'Unlock with fingerprint',
              subtitle: ref.watch(unlockAuthMethodProvider).valueOrNull ==
                      AuthMethod.biometric
                  ? 'Fingerprint or face · PIN still works as backup'
                  : 'Use fingerprint instead of typing your PIN each time',
              value: ref.watch(unlockAuthMethodProvider).valueOrNull ==
                  AuthMethod.biometric,
              onChanged: (v) => _onFingerprintUnlockChanged(context, ref, v),
            ),
          ],
          const SizedBox(height: 16),
          const _SectionLabel('Data'),
          SettingsNavCard(
            icon: SkyIcons.folder,
            iconColor: const Color(0xFFEF6C00),
            iconBackground: const Color(0xFFFFF3E0),
            title: 'Backup folder',
            subtitle: BackupFolderService.instance.displayLabel(
              ref.watch(backupFolderPathProvider),
            ),
            onTap: () => showPickBackupFolderFlow(context, ref),
          ),
          const SizedBox(height: 10),
          SettingsNavCard(
            icon: SkyIcons.archive,
            iconColor: const Color(0xFFEF6C00),
            iconBackground: const Color(0xFFFFF3E0),
            title: 'Export backup',
            subtitle: 'Compressed file · optional password',
            onTap: () => showExportBackupFlow(context, ref),
          ),
          const SizedBox(height: 10),
          SettingsNavCard(
            icon: SkyIcons.note,
            iconColor: const Color(0xFFEF6C00),
            iconBackground: const Color(0xFFFFF3E0),
            title: 'Import backup',
            subtitle: 'From Files or shared storage',
            onTap: () => showImportBackupFlow(context, ref),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('About & legal'),
          SettingsNavCard(
            icon: SkyIcons.info,
            iconColor: const Color(0xFF1E88E5),
            iconBackground: const Color(0xFFE3F2FD),
            title: 'About & help',
            subtitle: AppInfo.shortDescription,
            onTap: () => context.push(AppRoutes.aboutHelp),
          ),
          const SizedBox(height: 10),
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
            onTap: () => context.push(AppRoutes.faq),
          ),
          const SizedBox(height: 10),
          SettingsNavCard(
            icon: SkyIcons.lightbulb,
            iconColor: const Color(0xFF8E24AA),
            iconBackground: const Color(0xFFF3E5F5),
            title: 'Data safety & permissions',
            subtitle: 'Mic, calendar, exact alarms, notifications, Firebase',
            onTap: () => context.push(AppRoutes.dataSafety),
          ),
          const SizedBox(height: 20),
          AboutBrandCard(
            onOpenAbout: () => context.push(AppRoutes.aboutHelp),
          ),
        ],
      ),
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
          const SnackBar(content: Text('Could not verify - app lock stays on')),
        );
        return;
      }
    }

    await ref.read(appLockEnabledProvider.notifier).setEnabled(enabled);
    if (enabled) {
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

    final ok = await PrivacyAuthService.instance.authenticateWithBiometrics(
      reason: 'Confirm to switch back to PIN unlock',
    );
    if (!ok) {
      if (!context.mounted) return;
      final pinOk = await _confirmPinDialog(context) ?? false;
      if (!pinOk) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not verify - staying on fingerprint'),
          ),
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
      final created =
          await DeviceCalendarService.instance.ensureWritableCalendar();
      if (!context.mounted) return;
      if (created?.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No writable calendars found')),
        );
        return;
      }
      await ref.read(calendarSettingsProvider.notifier).setDefaultCalendar(
            id: created!.id!,
            name: created.name ?? 'SkyTask',
            isGoogleCalendar:
                DeviceCalendarService.instance.isGoogleCalendar(created),
          );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
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

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System default',
      };

  void _pickTheme(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.brand(context),
              fontWeight: FontWeight.w700,
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
