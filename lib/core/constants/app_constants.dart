/// App-wide constants for SkyTask.
abstract final class AppConstants {
  static const String appName = 'SkyTask';

  // Isar
  static const String isarName = 'skytask_db';

  // Notification channels (Android)
  static const String reminderChannelId = 'skytask_reminders';
  static const String reminderChannelName = 'Reminders';
  static const String reminderChannelDescription =
      'Reliable reminders that work offline and after reboot';

  // Secure storage keys
  static const String appLockEnabledKey = 'app_lock_enabled';
  static const String privateVaultEnabledKey = 'private_vault_enabled';
  static const String themeModeKey = 'theme_mode';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String privacySetupCompleteKey = 'privacy_setup_complete';

  static const int pinLength = 4;
  static const String calendarSyncEnabledKey = 'calendar_sync_enabled';
  static const String defaultCalendarIdKey = 'default_calendar_id';
  static const String defaultCalendarNameKey = 'default_calendar_name';
  static const String defaultCalendarIsGoogleKey = 'default_calendar_is_google';

  // WorkManager
  static const String reminderRescheduleTask = 'reminder_reschedule';
  static const String timezoneChangeTask = 'timezone_change';

  // AlarmManager callback port
  static const int alarmCallbackPort = 49821;
}
