import '../../../../core/services/alarm_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../calendar/data/device_calendar_service.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';

/// Orchestrates the full reminder pipeline (offline-first, never Firebase-only).
///
/// Flow:
/// 1. Save locally in Isar
/// 2. Schedule local notification
/// 3. Schedule AlarmManager exact alarm
/// 4. Optionally create/update device calendar event
/// 5. Store notificationId + calendarEventId
class ReminderSchedulerService {
  ReminderSchedulerService({
    required ReminderRepository repository,
    DeviceCalendarService? calendarService,
  })  : _repository = repository,
        _calendarService = calendarService ?? DeviceCalendarService.instance;

  final ReminderRepository _repository;
  final DeviceCalendarService _calendarService;

  Future<Reminder> schedule({
    required Reminder reminder,
    bool addToCalendar = false,
    String? calendarId,
  }) async {
    if (reminder.isCompleted) {
      await _repository.save(reminder);
      return reminder;
    }

    await _repository.save(reminder);

    final notificationId =
        await NotificationService.instance.scheduleReminder(reminder);
    final withId = reminder.copyWith(notificationId: notificationId);
    await AlarmService.instance.scheduleReminder(withId);

    var updated = withId.copyWith(
      updatedAt: DateTime.now(),
    );

    if (addToCalendar &&
        calendarId != null &&
        !reminder.isVoice &&
        !reminder.isPrivate) {
      updated = await _syncCalendarEvent(
        updated,
        calendarId: calendarId,
      );
    }

    await _repository.save(updated);
    return updated;
  }

  Future<void> cancel(Reminder reminder, {String? calendarId}) async {
    await NotificationService.instance.cancelForReminder(reminder);
    await AlarmService.instance.cancelForReminder(reminder);

    if (reminder.calendarEventId != null && calendarId != null) {
      await _calendarService.deleteEvent(
        calendarId,
        reminder.calendarEventId!,
      );
    }

    await _repository.delete(reminder.id);
  }

  Future<Reminder> update({
    required Reminder reminder,
    bool syncCalendar = false,
    String? calendarId,
  }) async {
    await NotificationService.instance.cancelForReminder(reminder);
    await AlarmService.instance.cancelForReminder(reminder);

    if (reminder.isCompleted) {
      if (!syncCalendar &&
          reminder.calendarEventId != null &&
          calendarId != null) {
        await _calendarService.deleteEvent(
          calendarId,
          reminder.calendarEventId!,
        );
        final cleared = reminder.copyWith(
          calendarEventId: null,
          updatedAt: DateTime.now(),
        );
        await _repository.save(cleared);
        return cleared;
      }
      await _repository.save(reminder.copyWith(updatedAt: DateTime.now()));
      return reminder;
    }

    final notificationId =
        await NotificationService.instance.scheduleReminder(reminder);
    final withId = reminder.copyWith(notificationId: notificationId);
    await AlarmService.instance.scheduleReminder(withId);

    var updated = withId.copyWith(
      updatedAt: DateTime.now(),
    );

    if (syncCalendar &&
        calendarId != null &&
        !reminder.isVoice &&
        !reminder.isPrivate) {
      updated = await _syncCalendarEvent(
        updated,
        calendarId: calendarId,
      );
    } else if ((reminder.isVoice ||
            reminder.isPrivate ||
            !syncCalendar) &&
        updated.calendarEventId != null &&
        calendarId != null) {
      await _calendarService.deleteEvent(
        calendarId,
        updated.calendarEventId!,
      );
      updated = updated.copyWith(clearCalendarEventId: true);
    }

    await _repository.save(updated);
    return updated;
  }

  Future<Reminder> _syncCalendarEvent(
    Reminder reminder, {
    required String calendarId,
  }) async {
    if (reminder.calendarEventId != null) {
      await _calendarService.updateEvent(
        reminder,
        calendarId: calendarId,
        eventId: reminder.calendarEventId!,
      );
      return reminder;
    }

    final eventId = await _calendarService.createEvent(
      reminder,
      calendarId: calendarId,
    );
    return reminder.copyWith(calendarEventId: eventId);
  }
}
