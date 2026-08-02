import '../../../../core/database/isar_collections.dart' as isar;
import '../../../../core/services/private_crypto_service.dart';
import '../../domain/entities/reminder.dart';

class ReminderMapper {
  static final _crypto = PrivateCryptoService.instance;

  static Reminder fromCollection(isar.ReminderCollection c) {
    return Reminder(
      id: c.uuid,
      title: _crypto.reveal(c.title) ?? c.title,
      description: _crypto.reveal(c.description),
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
      voicePath: c.voicePath,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  static isar.ReminderCollection toCollection(Reminder reminder) {
    final private = reminder.isPrivate;
    return isar.ReminderCollection()
      ..uuid = reminder.id
      ..title =
          _crypto.protect(reminder.title, isPrivate: private) ?? reminder.title
      ..description =
          _crypto.protect(reminder.description, isPrivate: private)
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
      ..voicePath = reminder.voicePath
      ..createdAt = reminder.createdAt
      ..updatedAt = reminder.updatedAt;
  }
}
