import 'package:equatable/equatable.dart';

import '../../../../core/constants/task_categories.dart';
import '../../../../core/services/voice_memo_service.dart';

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
    this.category = TaskCategories.personal,
    this.repeatType = RepeatType.none,
    this.notificationOffset = NotificationOffset.atTime,
    this.customOffsetMinutes,
    this.notificationId,
    this.calendarEventId,
    this.googleEventId,
    this.isPrivate = false,
    this.isCompleted = false,
    this.voicePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime reminderDateTime;
  final String category;
  final RepeatType repeatType;
  final NotificationOffset notificationOffset;
  final int? customOffsetMinutes;
  final int? notificationId;
  final String? calendarEventId;
  final String? googleEventId;
  final bool isPrivate;
  final bool isCompleted;
  final String? voicePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVoice => VoiceMemoService.hasVoice(voicePath);

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
    String? category,
    RepeatType? repeatType,
    NotificationOffset? notificationOffset,
    int? customOffsetMinutes,
    int? notificationId,
    String? calendarEventId,
    String? googleEventId,
    bool? isPrivate,
    bool? isCompleted,
    String? voicePath,
    bool clearVoicePath = false,
    bool clearCalendarEventId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      category: category ?? this.category,
      repeatType: repeatType ?? this.repeatType,
      notificationOffset: notificationOffset ?? this.notificationOffset,
      customOffsetMinutes: customOffsetMinutes ?? this.customOffsetMinutes,
      notificationId: notificationId ?? this.notificationId,
      calendarEventId: clearCalendarEventId
          ? null
          : (calendarEventId ?? this.calendarEventId),
      googleEventId: googleEventId ?? this.googleEventId,
      isPrivate: isPrivate ?? this.isPrivate,
      isCompleted: isCompleted ?? this.isCompleted,
      voicePath: clearVoicePath ? null : (voicePath ?? this.voicePath),
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
        category,
        repeatType,
        notificationOffset,
        customOffsetMinutes,
        notificationId,
        calendarEventId,
        googleEventId,
        isPrivate,
        isCompleted,
        voicePath,
        createdAt,
        updatedAt,
      ];
}
