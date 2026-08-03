import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../reminders/domain/entities/reminder.dart';
import '../../data/device_calendar_service.dart';
import '../../domain/calendar_entry.dart';

/// Bumped after reminder create/update/delete to refresh calendar views.
final remindersRevisionProvider = StateProvider<int>((ref) => 0);

void refreshReminders(WidgetRef ref) {
  ref.read(remindersRevisionProvider.notifier).state++;
}

class CalendarSettings {
  const CalendarSettings({
    required this.syncEnabled,
    this.defaultCalendarId,
    this.defaultCalendarName,
    this.isGoogleCalendar = false,
  });

  final bool syncEnabled;
  final String? defaultCalendarId;
  final String? defaultCalendarName;
  final bool isGoogleCalendar;

  bool get canSyncToCalendar =>
      syncEnabled && defaultCalendarId != null && defaultCalendarId!.isNotEmpty;
}

final calendarSettingsProvider =
    StateNotifierProvider<CalendarSettingsNotifier, CalendarSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CalendarSettingsNotifier(prefs);
});

class CalendarSettingsNotifier extends StateNotifier<CalendarSettings> {
  CalendarSettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  final _calendarService = DeviceCalendarService.instance;

  static CalendarSettings _load(SharedPreferences prefs) {
    return CalendarSettings(
      syncEnabled: prefs.getBool(AppConstants.calendarSyncEnabledKey) ?? false,
      defaultCalendarId: prefs.getString(AppConstants.defaultCalendarIdKey),
      defaultCalendarName: prefs.getString(AppConstants.defaultCalendarNameKey),
      isGoogleCalendar:
          prefs.getBool(AppConstants.defaultCalendarIsGoogleKey) ?? false,
    );
  }

  Future<bool> setSyncEnabled(bool enabled) async {
    if (enabled) {
      final granted = await _calendarService.requestPermissions();
      if (!granted) return false;

      final calendars = await _calendarService.getWritableCalendars();
      if (calendars.isEmpty) return false;

      final selected = _calendarService.pickPreferredCalendar(
        calendars,
        currentId: state.defaultCalendarId,
      );
      if (selected?.id == null) return false;

      final isGoogle = _calendarService.isGoogleCalendar(selected!);
      await _prefs.setBool(AppConstants.calendarSyncEnabledKey, true);
      await _prefs.setString(AppConstants.defaultCalendarIdKey, selected.id!);
      await _prefs.setString(
        AppConstants.defaultCalendarNameKey,
        selected.name ?? 'Calendar',
      );
      await _prefs.setBool(AppConstants.defaultCalendarIsGoogleKey, isGoogle);
      state = CalendarSettings(
        syncEnabled: true,
        defaultCalendarId: selected.id,
        defaultCalendarName: selected.name,
        isGoogleCalendar: isGoogle,
      );
      return true;
    }

    await _prefs.setBool(AppConstants.calendarSyncEnabledKey, false);
    state = CalendarSettings(
      syncEnabled: false,
      defaultCalendarId: state.defaultCalendarId,
      defaultCalendarName: state.defaultCalendarName,
      isGoogleCalendar: state.isGoogleCalendar,
    );
    return true;
  }

  Future<void> setDefaultCalendar({
    required String id,
    required String name,
    required bool isGoogleCalendar,
  }) async {
    await _prefs.setString(AppConstants.defaultCalendarIdKey, id);
    await _prefs.setString(AppConstants.defaultCalendarNameKey, name);
    await _prefs.setBool(AppConstants.defaultCalendarIsGoogleKey, isGoogleCalendar);
    state = CalendarSettings(
      syncEnabled: state.syncEnabled,
      defaultCalendarId: id,
      defaultCalendarName: name,
      isGoogleCalendar: isGoogleCalendar,
    );
  }
}

final calendarEntriesProvider =
    FutureProvider.family<List<CalendarEntry>, DateRange>((ref, range) async {
  ref.watch(remindersRevisionProvider);

  final repo = await ref.read(reminderRepositoryProvider.future);
  final reminders = await repo.getAll();

  final entries = reminders
      .where((r) => range.contains(r.reminderDateTime))
      .map(
        (r) => CalendarEntry(
          id: r.id,
          title: r.title,
          start: r.reminderDateTime,
          end: r.reminderDateTime.add(const Duration(minutes: 30)),
          description: r.description,
          source: CalendarEntrySource.reminder,
          reminder: r,
          isPrivate: r.isPrivate,
          isCompleted: r.isCompleted,
          hasCalendarSync: r.calendarEventId != null,
        ),
      )
      .toList();

  final settings = ref.read(calendarSettingsProvider);
  if (settings.syncEnabled && settings.defaultCalendarId != null) {
    try {
      final hasPermission = await _calendarService.hasPermissions();
      if (hasPermission) {
        final deviceEvents = await _calendarService.retrieveEvents(
          calendarIds: [settings.defaultCalendarId!],
          start: range.start,
          end: range.end,
        );

        final linkedEventIds = reminders
            .map((r) => r.calendarEventId)
            .whereType<String>()
            .toSet();

        for (final event in deviceEvents) {
          if (event.eventId == null ||
              linkedEventIds.contains(event.eventId)) {
            continue;
          }
          final start = event.start?.toLocal();
          if (start == null) continue;
          entries.add(
            CalendarEntry(
              id: 'device-${event.eventId}',
              title: event.title ?? 'Untitled event',
              start: start,
              end: event.end?.toLocal(),
              description: event.description,
              source: CalendarEntrySource.deviceCalendar,
            ),
          );
        }
      }
    } catch (_) {
      // Show local reminders even if device calendar read fails.
    }
  }

  entries.sort((a, b) => a.start.compareTo(b.start));
  return entries;
});

final _calendarService = DeviceCalendarService.instance;

class DateRange extends Equatable {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime point) =>
      !point.isBefore(start) && point.isBefore(end);

  @override
  List<Object?> get props => [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch];
}

DateRange agendaRange() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 90));
  return DateRange(start: start, end: end);
}

DateRange dayRange(DateTime day) {
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));
  return DateRange(start: start, end: end);
}

DateRange weekRange(DateTime anchor) {
  final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
  final start = DateTime(monday.year, monday.month, monday.day);
  final end = start.add(const Duration(days: 7));
  return DateRange(start: start, end: end);
}

DateRange monthRange(DateTime month) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);
  return DateRange(start: start, end: end);
}

String notificationOffsetLabel(NotificationOffset offset) {
  return switch (offset) {
    NotificationOffset.atTime => 'At reminder time',
    NotificationOffset.fiveMinutesBefore => '5 minutes before',
    NotificationOffset.tenMinutesBefore => '10 minutes before',
    NotificationOffset.thirtyMinutesBefore => '30 minutes before',
    NotificationOffset.oneHourBefore => '1 hour before',
    NotificationOffset.custom => 'Custom offset',
  };
}
