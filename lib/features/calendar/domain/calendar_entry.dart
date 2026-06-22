import 'package:equatable/equatable.dart';

import '../../reminders/domain/entities/reminder.dart';

enum CalendarEntrySource { reminder, deviceCalendar }

class CalendarEntry extends Equatable {
  const CalendarEntry({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.description,
    this.source = CalendarEntrySource.reminder,
    this.reminder,
    this.isPrivate = false,
    this.isCompleted = false,
    this.hasCalendarSync = false,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final String? description;
  final CalendarEntrySource source;
  final Reminder? reminder;
  final bool isPrivate;
  final bool isCompleted;
  final bool hasCalendarSync;

  @override
  List<Object?> get props => [
        id,
        title,
        start,
        end,
        description,
        source,
        reminder,
        isPrivate,
        isCompleted,
        hasCalendarSync,
      ];
}
