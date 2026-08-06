import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';

import '../../features/reminders/domain/entities/reminder.dart';
import 'isar_service.dart';
import 'notification_service.dart';
import 'private_crypto_service.dart';
import '../utils/stable_notification_id.dart';
import '../../features/reminders/data/repositories/reminder_repository_impl.dart';

/// Android AlarmManager exact-alarm layer for reliable local reminder wake-ups.
class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  /// Reserved; keep clear of reminder notification id space.
  static const int _bootRescheduleAlarmId = 0x7f000001;

  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  int _idFor(Reminder reminder) =>
      reminder.notificationId ?? stableNotificationId(reminder.id);

  /// Schedules an exact alarm that re-fires the local notification pipeline.
  Future<void> scheduleReminder(Reminder reminder) async {
    final fireAt = reminder.fireDateTime;
    if (!fireAt.isAfter(DateTime.now())) {
      // Overdue — no future alarm to arm.
      return;
    }

    final alarmId = _idFor(reminder);

    await AndroidAlarmManager.oneShotAt(
      fireAt,
      alarmId,
      _alarmCallback,
      exact: true,
      allowWhileIdle: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {'reminderId': reminder.id},
    );
  }

  Future<void> cancelReminder(int alarmId) async {
    await AndroidAlarmManager.cancel(alarmId);
  }

  Future<void> cancelForReminder(Reminder reminder) async {
    final id = _idFor(reminder);
    await cancelReminder(id);
    final legacy = reminder.id.hashCode & 0x7fffffff;
    if (legacy != id) {
      await cancelReminder(legacy);
    }
  }

  /// Re-registers future pending reminders after reboot / timezone / health check.
  ///
  /// Does **not** re-post overdue notifications into the shade (avoids the
  /// “old reminder pops again when I open the app” bug).
  Future<void> rescheduleAllReminders() async {
    await PrivateCryptoService.instance.init();
    final isar = await IsarService.instance.db;
    final repo = ReminderRepositoryImpl(isar);
    final reminders = await repo.getPending();
    final now = DateTime.now();

    for (final reminder in reminders) {
      final notificationId = _idFor(reminder);
      await NotificationService.instance.cancelForReminder(reminder);
      await cancelForReminder(reminder);

      if (!reminder.fireDateTime.isAfter(now)) {
        // Keep a stable id on disk; leave shade alone if user dismissed it.
        if (reminder.notificationId != notificationId) {
          await repo.save(reminder.copyWith(notificationId: notificationId));
        }
        continue;
      }

      final scheduledId = await NotificationService.instance.scheduleReminder(
        reminder.copyWith(notificationId: notificationId),
        showIfPastDue: false,
      );
      final withId = reminder.copyWith(notificationId: scheduledId);
      await scheduleReminder(withId);
      await repo.save(withId);
    }
  }

  /// One-shot delayed reschedule — only for true device reboot paths.
  /// Do **not** call from [main] on every cold start.
  static Future<void> scheduleBootReschedule() async {
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 5),
      _bootRescheduleAlarmId,
      _bootRescheduleCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }
}

@pragma('vm:entry-point')
void _alarmCallback(int id, Map<String, dynamic>? params) async {
  final reminderId = params?['reminderId'] as String?;
  if (reminderId == null) return;

  await PrivateCryptoService.instance.init();
  await NotificationService.instance.initialize();
  final isar = await IsarService.instance.db;
  final repo = ReminderRepositoryImpl(isar);
  final reminder = await repo.getById(reminderId);
  if (reminder == null || reminder.isCompleted) return;

  // Real fire path — post the notification if FLN did not already.
  await NotificationService.instance.scheduleReminder(
    reminder,
    showIfPastDue: true,
  );
}

@pragma('vm:entry-point')
void _bootRescheduleCallback() async {
  debugPrint('SkyTask: re-registering reminders after reboot');
  await PrivateCryptoService.instance.init();
  await NotificationService.instance.initialize();
  await AlarmService.instance.rescheduleAllReminders();
}
