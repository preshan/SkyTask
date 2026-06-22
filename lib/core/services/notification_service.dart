import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
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

  /// Schedules a zoned notification for [reminder] at the computed fire time.
  Future<int> scheduleReminder(Reminder reminder) async {
    final notificationId = reminder.notificationId ?? reminder.id.hashCode;
    final fireAt = reminder.fireDateTime;

    await _plugin.zonedSchedule(
      notificationId,
      reminder.title,
      reminder.description,
      tz.TZDateTime.from(fireAt, tz.local),
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
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
