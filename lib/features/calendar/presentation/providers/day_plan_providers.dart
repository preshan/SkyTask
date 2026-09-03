import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/utils/date_filters.dart';
import '../../domain/day_plan_item.dart';
import '../providers/calendar_providers.dart';

/// Timed tasks + reminders for a single calendar day.
final dayPlanItemsProvider =
    FutureProvider.family<List<DayPlanItem>, DateTime>((ref, day) async {
  ref.watch(remindersRevisionProvider);
  ref.watch(tasksRevisionProvider);

  final dayStart = DateTime(day.year, day.month, day.day);

  final reminderRepo = await ref.read(reminderRepositoryProvider.future);
  final taskRepo = await ref.read(taskRepositoryProvider.future);

  final reminders = await reminderRepo.getAll();
  final tasks = await taskRepo.getAll(includeArchived: false);

  final items = <DayPlanItem>[
    ...reminders
        .where((r) => DateFilters.isSameDay(r.reminderDateTime, dayStart))
        .map(DayPlanItem.fromReminder),
    ...tasks
        .where((t) =>
            !t.archived &&
            t.isTimed &&
            t.dueDate != null &&
            DateFilters.isSameDay(t.dueDate!, dayStart))
        .map(DayPlanItem.fromTask),
  ]..sort((a, b) => a.start.compareTo(b.start));

  return items;
});
