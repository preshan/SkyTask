import 'package:isar/isar.dart';

part 'isar_collections.g.dart';

@collection
class TaskCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String title;
  String? description;

  @enumerated
  late TaskPriority priority;

  @enumerated
  late TaskCategory category;

  List<String> tags = [];

  DateTime? dueDate;
  late bool completed;
  late bool pinned;
  late bool archived;
  late bool isPrivate;

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class ReminderCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String title;
  String? description;
  late DateTime reminderDateTime;

  @enumerated
  late RepeatType repeatType;

  @enumerated
  late NotificationOffset notificationOffset;

  int? customOffsetMinutes;
  int? notificationId;
  String? calendarEventId;
  String? googleEventId;
  late bool isPrivate;
  late bool isCompleted;

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class IdeaCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String title;
  late String content;
  List<String> tags = [];
  late bool isPrivate;

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class NoteCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String title;
  late String content;
  List<String> attachments = [];
  late bool isPrivate;

  late DateTime createdAt;
  late DateTime updatedAt;
}

enum TaskPriority { low, medium, high }

enum TaskCategory {
  work,
  personal,
  health,
  finance,
  study,
  shopping,
  custom,
}

enum RepeatType { none, daily, weekly, monthly, yearly }

enum NotificationOffset {
  atTime,
  fiveMinutesBefore,
  tenMinutesBefore,
  thirtyMinutesBefore,
  oneHourBefore,
  custom,
}
