import 'package:isar/isar.dart';

import '../../../../core/database/isar_collections.dart' as isar;
import '../../domain/entities/reminder.dart';

class ReminderMapper {
  static Reminder fromCollection(isar.ReminderCollection c) {
    return Reminder(
      id: c.uuid,
      title: c.title,
      description: c.description,
      reminderDateTime: c.reminderDateTime,
      repeatType: RepeatType.values[c.repeatType.index],
      notificationOffset:
          NotificationOffset.values[c.notificationOffset.index],
      customOffsetMinutes: c.customOffsetMinutes,
      notificationId: c.notificationId,
      calendarEventId: c.calendarEventId,
      googleEventId: c.googleEventId,
      isPrivate: c.isPrivate,
      isCompleted: c.isCompleted,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  static isar.ReminderCollection toCollection(Reminder reminder) {
    return isar.ReminderCollection()
      ..uuid = reminder.id
      ..title = reminder.title
      ..description = reminder.description
      ..reminderDateTime = reminder.reminderDateTime
      ..repeatType = isar.RepeatType.values[reminder.repeatType.index]
      ..notificationOffset =
          isar.NotificationOffset.values[reminder.notificationOffset.index]
      ..customOffsetMinutes = reminder.customOffsetMinutes
      ..notificationId = reminder.notificationId
      ..calendarEventId = reminder.calendarEventId
      ..googleEventId = reminder.googleEventId
      ..isPrivate = reminder.isPrivate
      ..isCompleted = reminder.isCompleted
      ..createdAt = reminder.createdAt
      ..updatedAt = reminder.updatedAt;
  }
}
