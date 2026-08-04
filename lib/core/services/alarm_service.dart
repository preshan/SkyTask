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

  static const int _bootRescheduleAlarmId = 9001;

  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  /// Schedules an exact alarm that re-fires the local notification pipeline.
  Future<void> scheduleReminder(Reminder reminder) async {
    final fireAt = reminder.fireDateTime;
    final alarmId =
        reminder.notificationId ?? stableNotificationId(reminder.id);

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

  /// Re-registers all pending reminders after reboot or app update.
  Future<void> rescheduleAllReminders() async {
    await PrivateCryptoService.instance.init();
    final isar = await IsarService.instance.db;
    final repo = ReminderRepositoryImpl(isar);
    final reminders = await repo.getPending();

    for (final reminder in reminders) {
      final notificationId =
          await NotificationService.instance.scheduleReminder(reminder);
      await scheduleReminder(
        reminder.copyWith(notificationId: notificationId),
      );
      await repo.save(reminder.copyWith(notificationId: notificationId));
    }
  }

  /// Boot-time reschedule entry point.
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

  await NotificationService.instance.scheduleReminder(reminder);
}

@pragma('vm:entry-point')
void _bootRescheduleCallback() async {
  debugPrint('SkyTask: re-registering reminders after reboot');
  await PrivateCryptoService.instance.init();
  await NotificationService.instance.initialize();
  await AlarmService.instance.rescheduleAllReminders();
}
