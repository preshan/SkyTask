import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
import '../utils/stable_notification_id.dart';
import '../../features/reminders/domain/entities/reminder.dart';

/// Local notification layer — works offline, app closed, and after reboot.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> initialize() async {
    if (_initialized) return;
    _initFuture ??= _doInitialize();
    await _initFuture;
  }

  Future<void> _doInitialize() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      AppConstants.reminderChannelId,
      AppConstants.reminderChannelName,
      description: AppConstants.reminderChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
    await _requestNotificationPermission(android);

    _initialized = true;
  }

  Future<void> _requestNotificationPermission(
    AndroidFlutterLocalNotificationsPlugin? android,
  ) async {
    if (android == null) return;

    try {
      final enabled = await android.areNotificationsEnabled();
      if (enabled == true) return;

      await android.requestNotificationsPermission();
    } on PlatformException catch (e) {
      // Android allows only one permission dialog at a time (e.g. hot restart
      // or debugger re-entry while a request is still showing).
      if (e.code != 'permissionRequestInProgress') rethrow;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    // Deep-link to reminder detail via payload in Phase 2.
  }

  int _idFor(Reminder reminder) =>
      reminder.notificationId ?? stableNotificationId(reminder.id);

  /// Schedules a zoned notification for [reminder] at the computed fire time.
  ///
  /// When [showIfPastDue] is false (health / reboot reschedule), overdue
  /// reminders are left alone — they are not re-posted into the shade.
  Future<int> scheduleReminder(
    Reminder reminder, {
    bool showIfPastDue = true,
  }) async {
    // AlarmManager / WorkManager callbacks run in a separate isolate and must
    // initialize timezones before using tz.local.
    await initialize();

    final notificationId = _idFor(reminder);
    final fireAt = reminder.fireDateTime;
    final scheduled = tz.TZDateTime.from(fireAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    final title =
        reminder.isPrivate ? 'Private reminder' : reminder.title;
    final body = reminder.isPrivate ? null : reminder.description;

    // Past-due: only show when this is a real fire path (alarm callback),
    // not when the app is merely re-registering schedules on open.
    if (!scheduled.isAfter(now)) {
      if (showIfPastDue) {
        await _plugin.show(
          notificationId,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              AppConstants.reminderChannelId,
              AppConstants.reminderChannelName,
              channelDescription: AppConstants.reminderChannelDescription,
              importance: Importance.max,
              priority: Priority.high,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
            ),
          ),
          payload: reminder.id,
        );
      }
      return notificationId;
    }

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.reminderChannelId,
          AppConstants.reminderChannelName,
          channelDescription: AppConstants.reminderChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id,
    );

    return notificationId;
  }

  Future<void> cancelReminder(int notificationId) async {
    await initialize();
    await _plugin.cancel(notificationId);
  }

  /// Cancels both the stored / stable id and a legacy [String.hashCode] id.
  Future<void> cancelForReminder(Reminder reminder) async {
    final id = _idFor(reminder);
    await cancelReminder(id);
    final legacy = reminder.id.hashCode & 0x7fffffff;
    if (legacy != id) {
      await cancelReminder(legacy);
    }
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}
