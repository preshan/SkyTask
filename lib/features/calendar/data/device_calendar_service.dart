import 'package:device_calendar/device_calendar.dart' hide Reminder;
import 'package:timezone/timezone.dart' as tz;

import '../../reminders/domain/entities/reminder.dart';

/// Phase 1: Device calendar integration (Android Calendar Provider).
/// On Android, Google calendars sync through the device calendar when a
/// Google account is added in system Settings.
class DeviceCalendarService {
  DeviceCalendarService._();
  static final DeviceCalendarService instance = DeviceCalendarService._();

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  Future<bool> requestPermissions() async {
    final result = await _plugin.requestPermissions();
    return result.isSuccess && result.data == true;
  }

  Future<bool> hasPermissions() async {
    final result = await _plugin.hasPermissions();
    return result.isSuccess && result.data == true;
  }

  Future<List<Calendar>> getWritableCalendars() async {
    final result = await _plugin.retrieveCalendars();
    if (!result.isSuccess || result.data == null) return [];
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

  bool isGoogleCalendar(Calendar calendar) {
    final account = calendar.accountName?.toLowerCase() ?? '';
    final type = calendar.accountType?.toLowerCase() ?? '';
    final name = calendar.name?.toLowerCase() ?? '';
    return account.contains('google') ||
        account.contains('gmail') ||
        type.contains('com.google') ||
        name.contains('google');
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
  Future<String?> createEvent(Reminder reminder) async {
    return null;
  }

  @override
  Future<void> deleteEvent(String googleEventId) async {}

  @override
  Future<void> updateEvent(Reminder reminder) async {}
}
