import '../../reminders/domain/entities/reminder.dart';
import '../../tasks/domain/entities/task.dart';

enum DayPlanKind { task, reminder }

/// Unified timed block for the Day Plan timeline.
class DayPlanItem {
  const DayPlanItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.category,
    required this.start,
    required this.end,
    required this.isCompleted,
    required this.isPrivate,
    this.task,
    this.reminder,
  });

  final String id;
  final DayPlanKind kind;
  final String title;
  final String category;
  final DateTime start;
  final DateTime end;
  final bool isCompleted;
  final bool isPrivate;
  final Task? task;
  final Reminder? reminder;

  int get durationMinutes {
    final mins = end.difference(start).inMinutes;
    return mins <= 0 ? 30 : mins;
  }

  factory DayPlanItem.fromTask(Task task) {
    final start = task.plannedStart!;
    return DayPlanItem(
      id: task.id,
      kind: DayPlanKind.task,
      title: task.title,
      category: task.category,
      start: start,
      end: task.plannedEnd ?? start.add(const Duration(minutes: 30)),
      isCompleted: task.completed,
      isPrivate: task.isPrivate,
      task: task,
    );
  }

  factory DayPlanItem.fromReminder(Reminder reminder) {
    return DayPlanItem(
      id: reminder.id,
      kind: DayPlanKind.reminder,
      title: reminder.title,
      category: reminder.category,
      start: reminder.reminderDateTime,
      end: reminder.plannedEnd,
      isCompleted: reminder.isCompleted,
      isPrivate: reminder.isPrivate,
      reminder: reminder,
    );
  }
}
