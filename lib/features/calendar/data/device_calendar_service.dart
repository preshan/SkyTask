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

  /// Requests calendar READ + WRITE. The device_calendar plugin requires both;
  /// write-only alone is not enough to list or create calendars.
  Future<bool> requestPermissions() async {
    final granted = await _ensureReadAndWriteGranted();
    if (!granted) {
      debugPrint('Calendar: READ+WRITE not granted');
      return false;
    }

    // Keep device_calendar's internal check in sync.
    try {
      final plugin = await _plugin.requestPermissions();
      debugPrint(
        'Calendar: plugin.requestPermissions '
        'ok=${plugin.isSuccess} data=${plugin.data} '
        'err=${plugin.errors.map((e) => e.errorMessage).join(', ')}',
      );
    } catch (e) {
      debugPrint('device_calendar requestPermissions: $e');
    }

    // Verify the plugin itself sees both permissions (it checks Activity).
    final pluginOk = await _pluginHasPermissions();
    if (!pluginOk) {
      debugPrint('Calendar: plugin.hasPermissions still false after grant');
      // One more attempt — OEMs sometimes need the plugin dialog path.
      try {
        await _plugin.requestPermissions();
      } catch (_) {}
      return _pluginHasPermissions();
    }
    return true;
  }

  Future<bool> hasPermissions() async {
    final read = await Permission.calendarFullAccess.status;
    if (read.isGranted) return true;
    return _pluginHasPermissions();
  }

  Future<bool> isPermanentlyDenied() async {
    final full = await Permission.calendarFullAccess.status;
    if (full.isPermanentlyDenied) return true;
    final writeOnly = await Permission.calendarWriteOnly.status;
    return writeOnly.isPermanentlyDenied;
  }

  Future<bool> _ensureReadAndWriteGranted() async {
    // calendarFullAccess → READ_CALENDAR + WRITE_CALENDAR on Android.
    var full = await Permission.calendarFullAccess.status;
    if (!full.isGranted && !full.isPermanentlyDenied) {
      full = await Permission.calendarFullAccess.request();
    }
    if (full.isGranted) return true;

    // Older / OEM split: ask write-only, then retry full (for read).
    var write = await Permission.calendarWriteOnly.status;
    if (!write.isGranted && !write.isPermanentlyDenied) {
      write = await Permission.calendarWriteOnly.request();
    }
    if (!write.isGranted) return false;

    full = await Permission.calendarFullAccess.status;
    if (!full.isGranted && !full.isPermanentlyDenied) {
      full = await Permission.calendarFullAccess.request();
    }
    return full.isGranted;
  }

  Future<bool> _pluginHasPermissions() async {
    try {
      final result = await _plugin.hasPermissions();
      return result.isSuccess && result.data == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Calendar>> retrieveAllCalendars() async {
    final result = await _plugin.retrieveCalendars();
    if (!result.isSuccess || result.data == null) {
      debugPrint(
        'retrieveCalendars failed: ${result.errors.map((e) => e.errorMessage).join(', ')}',
      );
      return [];
    }
    final all = result.data!;
    debugPrint(
      'Calendar: retrieveAll=${all.length} '
      '[${all.map((c) => '${c.name}(id=${c.id}, ro=${c.isReadOnly}, '
          'acct=${c.accountName}/${c.accountType})').join('; ')}]',
    );
    return all;
  }

  Future<List<Calendar>> getWritableCalendars() async {
    final all = await retrieveAllCalendars();
    final writable = all.where(_isWritable).toList();
    if (writable.isEmpty && all.isNotEmpty) {
      debugPrint(
        'Calendar: ${all.length} found, 0 writable '
        '(${all.where((c) => c.isReadOnly == true).length} read-only)',
      );
    } else if (all.isEmpty) {
      debugPrint('Calendar: retrieveCalendars returned 0 calendars');
    }
    return writable;
  }

  bool _isWritable(Calendar c) =>
      c.isReadOnly != true && (c.id?.isNotEmpty ?? false);

  Future<List<Calendar>> getReadableCalendars() async {
    return retrieveAllCalendars();
  }

  Future<List<Calendar>> getGoogleCalendars() async {
    final calendars = await getWritableCalendars();
    return calendars.where(isGoogleCalendar).toList();
  }

  /// Prefers an existing writable calendar; otherwise creates a local
  /// "SkyTask" calendar so sync can enable on devices with no accounts yet.
  Future<Calendar?> ensureWritableCalendar({String? preferredId}) async {
    var writable = await getWritableCalendars();
    if (writable.isEmpty) {
      // Provider can lag right after the permission dialog.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      writable = await getWritableCalendars();
    }

    final existing = pickPreferredCalendar(writable, currentId: preferredId);
    if (existing != null) return existing;

    debugPrint('Calendar: creating local SkyTask calendar fallback');
    final created = await _createLocalSkyTaskCalendar();
    if (created != null) return created;

    // Last retry after create / account provider settle.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    writable = await getWritableCalendars();
    return pickPreferredCalendar(writable, currentId: preferredId);
  }

  Future<Calendar?> _createLocalSkyTaskCalendar() async {
    for (final accountName in ['SkyTask', 'Device Calendar']) {
      try {
        final created = await _plugin.createCalendar(
          'SkyTask',
          localAccountName: accountName,
        );
        if (!created.isSuccess ||
            created.data == null ||
            created.data!.isEmpty) {
          debugPrint(
            'createCalendar($accountName) failed: '
            '${created.errors.map((e) => e.errorMessage).join(', ')}',
          );
          continue;
        }
        final newId = created.data!;
        debugPrint(
          'Calendar: created local calendar id=$newId acct=$accountName',
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final writable = await getWritableCalendars();
        final match = pickPreferredCalendar(writable, currentId: newId);
        if (match != null) return match;
        // Plugin may return the id before the calendar is listed as writable.
        return Calendar(
          id: newId,
          name: 'SkyTask',
          accountName: accountName,
          accountType: 'LOCAL',
          isReadOnly: false,
        );
      } catch (e) {
        debugPrint('createCalendar($accountName) error: $e');
      }
    }
    return null;
  }

  Calendar? pickPreferredCalendar(List<Calendar> calendars, {String? currentId}) {
    if (calendars.isEmpty) return null;

    if (currentId != null) {
      for (final calendar in calendars) {
        if (calendar.id == currentId) return calendar;
      }
    }

    final google = calendars.where(isGoogleCalendar).toList();
    if (google.isNotEmpty) {
      final primary = google.where((c) => c.isDefault == true).toList();
      if (primary.isNotEmpty) return primary.first;
      return google.first;
    }
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
