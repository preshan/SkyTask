import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/task_categories.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../reminders/presentation/widgets/reminder_form_sheet.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../../domain/day_plan_item.dart';
import '../providers/calendar_providers.dart';
import '../providers/day_plan_providers.dart';

const _kDayStartHour = 6;
const _kDayEndHour = 22;
const _kSlotMinutes = 30;
const _kHourHeight = 104.0;

double get _pixelsPerMinute => _kHourHeight / 60.0;

/// Vertical Day Plan timeline for one [day].
class DayPlanView extends ConsumerWidget {
  const DayPlanView({
    super.key,
    required this.day,
    this.privateOnly = false,
    this.categoryFilter,
  });

  final DateTime day;
  final bool privateOnly;
  final String? categoryFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(dayPlanItemsProvider(day));

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        var items = all;
        if (privateOnly) {
          items = items.where((i) => i.isPrivate).toList();
        }
        if (categoryFilter != null) {
          final f = categoryFilter!.toLowerCase();
          items = items.where((i) => i.category.toLowerCase() == f).toList();
        }

        const totalMinutes = (_kDayEndHour - _kDayStartHour) * 60;
        final height = totalMinutes * _pixelsPerMinute;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 24),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                _DayPlanGrid(
                  day: day,
                  onSlotTap: (slotStart) =>
                      _onEmptySlotTap(context, ref, slotStart),
                ),
                ..._positionedBlocks(context, ref, items),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _positionedBlocks(
    BuildContext context,
    WidgetRef ref,
    List<DayPlanItem> items,
  ) {
    final dayStart = DateTime(day.year, day.month, day.day, _kDayStartHour);
    final dayEnd = DateTime(day.year, day.month, day.day, _kDayEndHour);
    final widgets = <Widget>[];

    // Simple overlap columns.
    final columns = <List<DayPlanItem>>[];
    for (final item in items) {
      var placed = false;
      for (final col in columns) {
        final last = col.last;
        if (!item.start.isBefore(last.end)) {
          col.add(item);
          placed = true;
          break;
        }
      }
      if (!placed) columns.add([item]);
    }

    final colCount = columns.isEmpty ? 1 : columns.length;
    for (var c = 0; c < columns.length; c++) {
      for (final item in columns[c]) {
        var start = item.start;
        var end = item.end;
        if (end.isBefore(dayStart) || !start.isBefore(dayEnd)) continue;
        if (start.isBefore(dayStart)) start = dayStart;
        if (end.isAfter(dayEnd)) end = dayEnd;

        final top =
            start.difference(dayStart).inMinutes * _pixelsPerMinute;
        final blockHeight = (end.difference(start).inMinutes *
                _pixelsPerMinute)
            .clamp(36.0, double.infinity);

        const leftGutter = 72.0;
        final available = MediaQuery.sizeOf(context).width - leftGutter - 20;
        final width = available / colCount - 4;
        final left = leftGutter + c * (width + 4);

        widgets.add(
          Positioned(
            top: top,
            left: left,
            width: width,
            height: blockHeight,
            child: _DayPlanBlock(
              item: item,
              onTap: () => _onBlockTap(context, ref, item),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Future<void> _onEmptySlotTap(
    BuildContext context,
    WidgetRef ref,
    DateTime slotStart,
  ) async {
    final kind = await showModalBottomSheet<DayPlanKind>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Add at ${DateFormat.jm().format(slotStart)}',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: SkyIcon(
                  SkyIcons.task,
                  color: AppColors.brand(ctx),
                ),
                title: const Text('Task'),
                onTap: () => Navigator.pop(ctx, DayPlanKind.task),
              ),
              ListTile(
                leading: SkyIcon(
                  SkyIcons.alarm,
                  color: AppColors.brand(ctx),
                ),
                title: const Text('Reminder'),
                onTap: () => Navigator.pop(ctx, DayPlanKind.reminder),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (kind == null || !context.mounted) return;

    if (kind == DayPlanKind.task) {
      await showTaskFormSheet(
        context,
        ref,
        initialDateTime: slotStart,
        planDurationMinutes: 30,
      );
    } else {
      await showReminderFormSheet(
        context,
        ref,
        initialDateTime: slotStart,
        planDurationMinutes: 30,
      );
    }
  }

  Future<void> _onBlockTap(
    BuildContext context,
    WidgetRef ref,
    DayPlanItem item,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final completeLabel =
            item.isCompleted ? 'Mark incomplete' : 'Mark complete';
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${DateFormat.jm().format(item.start)} - ${DateFormat.jm().format(item.end)} · ${item.kind == DayPlanKind.task ? 'Task' : 'Reminder'}',
                ),
              ),
              ListTile(
                leading: const SkyIcon(SkyIcons.edit),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: SkyIcon(
                  item.isCompleted ? SkyIcons.pending : SkyIcons.tasks,
                ),
                title: Text(completeLabel),
                onTap: () => Navigator.pop(ctx, 'toggle'),
              ),
              ListTile(
                leading: const SkyIcon(SkyIcons.event),
                title: const Text('Change time'),
                onTap: () => Navigator.pop(ctx, 'time'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case 'edit':
        if (item.kind == DayPlanKind.task && item.task != null) {
          await showTaskFormSheet(context, ref, task: item.task);
        } else if (item.reminder != null) {
          await showReminderFormSheet(context, ref, reminder: item.reminder);
        }
      case 'toggle':
        await _toggleComplete(ref, item);
      case 'time':
        await _changeTime(context, ref, item);
    }
  }

  Future<void> _toggleComplete(WidgetRef ref, DayPlanItem item) async {
    if (item.kind == DayPlanKind.task && item.task != null) {
      final repo = await ref.read(taskRepositoryProvider.future);
      await repo.toggleComplete(item.task!.id);
      refreshTasks(ref);
      return;
    }
    if (item.reminder != null) {
      final settings = ref.read(calendarSettingsProvider);
      final scheduler = await ref.read(reminderSchedulerProvider.future);
      final updated = item.reminder!.copyWith(
        isCompleted: !item.reminder!.isCompleted,
        updatedAt: DateTime.now(),
      );
      await scheduler.update(
        reminder: updated,
        syncCalendar: false,
        calendarId: settings.defaultCalendarId,
      );
      refreshReminders(ref);
    }
  }

  Future<void> _changeTime(
    BuildContext context,
    WidgetRef ref,
    DayPlanItem item,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(item.start),
    );
    if (picked == null || !context.mounted) return;

    final newStart = DateTime(
      day.year,
      day.month,
      day.day,
      picked.hour,
      picked.minute,
    );

    if (item.kind == DayPlanKind.task && item.task != null) {
      final mins = picked.hour * 60 + picked.minute;
      final repo = await ref.read(taskRepositoryProvider.future);
      await repo.save(
        item.task!.copyWith(
          dueDate: DateTime(day.year, day.month, day.day),
          dueTimeMinutes: mins,
          updatedAt: DateTime.now(),
        ),
      );
      refreshTasks(ref);
      return;
    }

    if (item.reminder != null) {
      final settings = ref.read(calendarSettingsProvider);
      final scheduler = await ref.read(reminderSchedulerProvider.future);
      final updated = item.reminder!.copyWith(
        reminderDateTime: newStart,
        updatedAt: DateTime.now(),
      );
      await scheduler.update(
        reminder: updated,
        syncCalendar:
            settings.canSyncToCalendar && !updated.isVoice && !updated.isPrivate,
        calendarId: settings.defaultCalendarId,
      );
      refreshReminders(ref);
    }
  }
}

class _DayPlanGrid extends StatelessWidget {
  const _DayPlanGrid({
    required this.day,
    required this.onSlotTap,
  });

  final DateTime day;
  final ValueChanged<DateTime> onSlotTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = scheme.outlineVariant.withValues(alpha: 0.45);
    final slots = <Widget>[];

    for (var hour = _kDayStartHour; hour < _kDayEndHour; hour++) {
      for (var half = 0; half < 2; half++) {
        final slotStart = DateTime(day.year, day.month, day.day, hour, half * 30);
        final isHour = half == 0;
        slots.add(
          SizedBox(
            height: _kSlotMinutes * _pixelsPerMinute,
            child: InkWell(
              onTap: () => onSlotTap(slotStart),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: isHour
                        ? Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              DateFormat.j().format(slotStart),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: line,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(width: 1.5, color: line),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: line, width: 1),
                        ),
                      ),
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      child: Text(
                        DateFormat.Hm().format(slotStart),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Column(children: slots);
  }
}

class _DayPlanBlock extends ConsumerWidget {
  const _DayPlanBlock({
    required this.item,
    required this.onTap,
  });

  final DayPlanItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(customTaskCategoriesProvider);
    final overrides = ref.watch(defaultCategoryColorsProvider);
    final colorValue = TaskCategories.colorFor(
      item.category,
      custom: custom,
      defaultOverrides: overrides,
    );
    final fill = Color(colorValue);
    final onFill = fill.computeLuminance() > 0.55
        ? const Color(0xFF3D3D3D)
        : Colors.white;
    final muted = item.isCompleted;

    final timeLabel =
        '${DateFormat.jm().format(item.start)} - ${DateFormat.jm().format(item.end)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: fill.withValues(alpha: muted ? 0.28 : 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: fill.withValues(alpha: muted ? 0.35 : 0.85),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.1,
                                    fontSize: 13,
                                    decoration: muted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: onFill.withValues(
                                      alpha: muted ? 0.65 : 1,
                                    ),
                                  ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          timeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    height: 1.1,
                                    color: onFill.withValues(alpha: 0.7),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
