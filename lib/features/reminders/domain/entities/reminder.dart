import 'package:equatable/equatable.dart';

enum RepeatType { none, daily, weekly, monthly, yearly }

enum NotificationOffset {
  atTime,
  fiveMinutesBefore,
  tenMinutesBefore,
  thirtyMinutesBefore,
  oneHourBefore,
  custom,
}

class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.reminderDateTime,
    this.repeatType = RepeatType.none,
    this.notificationOffset = NotificationOffset.atTime,
    this.customOffsetMinutes,
    this.notificationId,
    this.calendarEventId,
    this.googleEventId,
    this.isPrivate = false,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime reminderDateTime;
  final RepeatType repeatType;
  final NotificationOffset notificationOffset;
  final int? customOffsetMinutes;
  final int? notificationId;
  final String? calendarEventId;
  final String? googleEventId;
  final bool isPrivate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Computed fire time based on notification offset.
  DateTime get fireDateTime {
    final offset = switch (notificationOffset) {
      NotificationOffset.atTime => Duration.zero,
      NotificationOffset.fiveMinutesBefore => const Duration(minutes: 5),
      NotificationOffset.tenMinutesBefore => const Duration(minutes: 10),
      NotificationOffset.thirtyMinutesBefore => const Duration(minutes: 30),
      NotificationOffset.oneHourBefore => const Duration(hours: 1),
      NotificationOffset.custom =>
        Duration(minutes: customOffsetMinutes ?? 0),
    };
    return reminderDateTime.subtract(offset);
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? reminderDateTime,
    RepeatType? repeatType,
    NotificationOffset? notificationOffset,
    int? customOffsetMinutes,
    int? notificationId,
    String? calendarEventId,
    String? googleEventId,
    bool? isPrivate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      repeatType: repeatType ?? this.repeatType,
      notificationOffset: notificationOffset ?? this.notificationOffset,
      customOffsetMinutes: customOffsetMinutes ?? this.customOffsetMinutes,
      notificationId: notificationId ?? this.notificationId,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      googleEventId: googleEventId ?? this.googleEventId,
      isPrivate: isPrivate ?? this.isPrivate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        reminderDateTime,
        repeatType,
        notificationOffset,
        customOffsetMinutes,
        notificationId,
        calendarEventId,
        googleEventId,
        isPrivate,
        isCompleted,
        createdAt,
        updatedAt,
      ];
}
