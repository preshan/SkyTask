import 'package:device_calendar/device_calendar.dart' hide Reminder;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../reminders/domain/entities/reminder.dart';

/// Why enabling calendar sync failed (for accurate UI copy).
enum CalendarSyncFailure {
  permissionDenied,
  permanentlyDenied,
  noCalendars,
}

/// Result of [CalendarSettingsNotifier.setSyncEnabled].
class CalendarSyncEnableResult {
  const CalendarSyncEnableResult.ok()
      : success = true,
        failure = null;

  const CalendarSyncEnableResult.fail(this.failure) : success = false;

  final bool success;
  final CalendarSyncFailure? failure;
}

/// Device calendar via Android Calendar Provider (includes Google calendars
/// when a Google account is added in system Settings and syncing).
class DeviceCalendarService {
  DeviceCalendarService._();
  static final DeviceCalendarService instance = DeviceCalendarService._();

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  /// Requests calendar access using [permission_handler] (reliable on Android 13+)
  /// and also notifies the device_calendar plugin.
  Future<bool> requestPermissions() async {
    final status = await _requestCalendarPermission();
    if (!status.isGranted) {
      debugPrint('Calendar permission status: $status');
      return false;
    }

    // Keep device_calendar's internal flag in sync when possible.
    try {
      await _plugin.requestPermissions();
    } catch (e) {
      debugPrint('device_calendar requestPermissions: $e');
    }
    return true;
  }

  Future<bool> hasPermissions() async {
    final full = await Permission.calendarFullAccess.status;
    if (full.isGranted) return true;
    final writeOnly = await Permission.calendarWriteOnly.status;
    if (writeOnly.isGranted) return true;
    try {
      final result = await _plugin.hasPermissions();
      return result.isSuccess && result.data == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPermanentlyDenied() async {
    final status = await Permission.calendarFullAccess.status;
    if (status.isPermanentlyDenied) return true;
    final writeOnly = await Permission.calendarWriteOnly.status;
    return writeOnly.isPermanentlyDenied;
  }

  Future<PermissionStatus> _requestCalendarPermission() async {
    var status = await Permission.calendarFullAccess.status;
    if (status.isGranted) return status;

    status = await Permission.calendarFullAccess.request();
    if (status.isGranted) return status;

    // Older Android / OEM paths map write-only separately.
    final writeOnly = await Permission.calendarWriteOnly.request();
    return writeOnly.isGranted ? writeOnly : status;
  }

  Future<List<Calendar>> getWritableCalendars() async {
    final result = await _plugin.retrieveCalendars();
    if (!result.isSuccess || result.data == null) {
      debugPrint(
        'retrieveCalendars failed: ${result.errors.map((e) => e.errorMessage).join(', ')}',
      );
      return [];
    }
    return result.data!.where((c) => c.isReadOnly != true).toList();
  }

  Future<List<Calendar>> getGoogleCalendars() async {
    final calendars = await getWritableCalendars();
    return calendars.where(isGoogleCalendar).toList();
  }

  Calendar? pickPreferredCalendar(List<Calendar> calendars, {String? currentId}) {
    if (calendars.isEmpty) return null;

    if (currentId != null) {
      for (final calendar in calendars) {
        if (calendar.id == currentId) return calendar;
      }
    }

    final google = calendars.where(isGoogleCalendar).toList();
    if (google.isNotEmpty) return google.first;
    return calendars.first;
  }

  /// Google calendars on Android often use accountType `com.google` and an email
  /// as accountName — not the literal string "google".
  bool isGoogleCalendar(Calendar calendar) {
    final account = calendar.accountName?.toLowerCase() ?? '';
    final type = calendar.accountType?.toLowerCase() ?? '';
    final name = calendar.name?.toLowerCase() ?? '';
    return type.contains('com.google') ||
        type.contains('google') ||
        account.contains('google') ||
        account.contains('gmail') ||
        account.endsWith('@gmail.com') ||
        account.endsWith('@googlemail.com') ||
        name.contains('google') ||
        name.contains('gmail');
  }

  Future<List<Event>> retrieveEvents({
    required List<String> calendarIds,
    required DateTime start,
    required DateTime end,
  }) async {
    if (calendarIds.isEmpty) return [];

    final events = <Event>[];
    for (final calendarId in calendarIds) {
      try {
        final result = await _plugin
            .retrieveEvents(
              calendarId,
              RetrieveEventsParams(
                startDate: start,
                endDate: end,
              ),
            )
            .timeout(const Duration(seconds: 8));
        if (result.isSuccess && result.data != null) {
          events.addAll(result.data!);
        }
      } catch (_) {
        // Skip slow/unavailable calendars instead of blocking the UI.
      }
    }

    events.sort((a, b) {
      final aStart = a.start?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bStart = b.start?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aStart.compareTo(bStart);
    });
    return events;
  }

  Future<String?> createEvent(
    Reminder reminder, {
    required String calendarId,
  }) async {
    final start = tz.TZDateTime.from(reminder.reminderDateTime, tz.local);
    final end = start.add(const Duration(minutes: 30));

    final event = Event(calendarId)
      ..title = reminder.title
      ..description = reminder.description
      ..start = start
      ..end = end;

    final result = await _plugin.createOrUpdateEvent(event);
    if (result == null || !result.isSuccess) return null;
    return result.data;
  }

  Future<void> updateEvent(
    Reminder reminder, {
    required String calendarId,
    required String eventId,
  }) async {
    final start = tz.TZDateTime.from(reminder.reminderDateTime, tz.local);
    final end = start.add(const Duration(minutes: 30));

    final event = Event(calendarId, eventId: eventId)
      ..title = reminder.title
      ..description = reminder.description
      ..start = start
      ..end = end;

    await _plugin.createOrUpdateEvent(event);
  }

  Future<void> deleteEvent(String calendarId, String eventId) async {
    await _plugin.deleteEvent(calendarId, eventId);
  }
}

/// Phase 2 placeholder: Google Calendar API via OAuth.
abstract class GoogleCalendarService {
  Future<String?> createEvent(Reminder reminder);
  Future<void> updateEvent(Reminder reminder);
  Future<void> deleteEvent(String googleEventId);
}

class GoogleCalendarServiceImpl implements GoogleCalendarService {
  @override
  Future<String?> createEvent(Reminder reminder) {
    return Future.value(null);
  }

  @override
  Future<void> deleteEvent(String googleEventId) async {}

  @override
  Future<void> updateEvent(Reminder reminder) async {}
}
