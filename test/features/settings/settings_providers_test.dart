import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skytask/core/constants/app_constants.dart';
import 'package:skytask/core/di/providers.dart';
import 'package:skytask/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:skytask/features/privacy/data/pin_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    PinStorageService.debugUseMemoryStore();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    PinStorageService.debugDisableMemoryStore();
  });

  group('Theme settings', () {
    test('defaults to system and persists light/dark', () async {
      expect(container.read(themeModeProvider), ThemeMode.system);

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString(AppConstants.themeModeKey), 'dark');

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString(AppConstants.themeModeKey), 'light');
    });
  });

  group('App lock settings', () {
    test('enable and disable persist', () async {
      expect(container.read(appLockEnabledProvider), isFalse);
      await container.read(appLockEnabledProvider.notifier).setEnabled(true);
      expect(container.read(appLockEnabledProvider), isTrue);
      expect(prefs.getBool(AppConstants.appLockEnabledKey), isTrue);

      await container.read(appLockEnabledProvider.notifier).setEnabled(false);
      expect(container.read(appLockEnabledProvider), isFalse);
    });
  });

  group('Backup folder preference', () {
    test('provider reflects prefs and updates', () {
      expect(container.read(backupFolderPathProvider), isNull);
      container.read(backupFolderPathProvider.notifier).state =
          '/tmp/SkyTaskBackups';
      expect(container.read(backupFolderPathProvider), '/tmp/SkyTaskBackups');
    });
  });

  group('Calendar settings', () {
    test('sync off by default; default calendar can be set', () async {
      final settings = container.read(calendarSettingsProvider);
      expect(settings.syncEnabled, isFalse);

      await container.read(calendarSettingsProvider.notifier).setDefaultCalendar(
            id: 'cal-1',
            name: 'Personal',
            isGoogleCalendar: true,
          );
      final updated = container.read(calendarSettingsProvider);
      expect(updated.defaultCalendarId, 'cal-1');
      expect(updated.defaultCalendarName, 'Personal');
      expect(updated.isGoogleCalendar, isTrue);
    });
  });

  group('Onboarding / privacy setup flags', () {
    test('complete flags flip and persist', () async {
      expect(container.read(onboardingCompleteProvider), isFalse);
      expect(container.read(privacySetupCompleteProvider), isFalse);

      await container.read(onboardingCompleteProvider.notifier).complete();
      await container.read(privacySetupCompleteProvider.notifier).complete();

      expect(container.read(onboardingCompleteProvider), isTrue);
      expect(container.read(privacySetupCompleteProvider), isTrue);
      expect(prefs.getBool(AppConstants.onboardingCompleteKey), isTrue);
      expect(prefs.getBool(AppConstants.privacySetupCompleteKey), isTrue);
    });
  });

  group('Unlock auth method provider', () {
    test('tracks PIN then biometric preference', () async {
      final pin = PinStorageService.instance;
      await pin.clear();
      await pin.savePin('9999');

      container.invalidate(unlockAuthMethodProvider);
      expect(await container.read(unlockAuthMethodProvider.future), AuthMethod.pin);

      await pin.setBiometricMethod();
      container.invalidate(unlockAuthMethodProvider);
      expect(
        await container.read(unlockAuthMethodProvider.future),
        AuthMethod.biometric,
      );
    });
  });

  group('Privacy lock notifier', () {
    test('lock and unlock toggle runtime state', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      await prefs.setBool(AppConstants.privacySetupCompleteKey, true);
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);

      // lockOnStart true when setup done + enabled
      expect(c.read(privacyLockProvider), isTrue);
      c.read(privacyLockProvider.notifier).unlock();
      expect(c.read(privacyLockProvider), isFalse);
      c.read(privacyLockProvider.notifier).lock();
      expect(c.read(privacyLockProvider), isTrue);
    });
  });
}
