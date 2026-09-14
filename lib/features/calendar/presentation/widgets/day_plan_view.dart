import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/task_categories.dart';
import '../../../../shared/widgets/async_error_view.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../reminders/presentation/widgets/reminder_form_sheet.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../../domain/day_plan_item.dart';
import '../providers/day_plan_providers.dart';

const _kDayStartHour = 6;
const _kDayEndHour = 22;
const _kSlotMinutes = 30;
const _kHourHeight = 88.0;

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
      error: (e, _) => AsyncErrorView(
        error: e,
        onRetry: () => ref.invalidate(dayPlanItemsProvider(day)),
      ),
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
            .clamp(28.0, double.infinity);

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
    if (item.kind == DayPlanKind.task && item.task != null) {
      await showTaskFormSheet(context, ref, task: item.task);
      return;
    }
    if (item.reminder != null) {
      await showReminderFormSheet(context, ref, reminder: item.reminder);
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
    final brand = AppColors.brand(context);
    final line = brand.withValues(alpha: 0.45);
    final lineStrong = brand.withValues(alpha: 0.7);
    final slots = <Widget>[];

    for (var hour = _kDayStartHour; hour < _kDayEndHour; hour++) {
      for (var half = 0; half < 2; half++) {
        final slotStart = DateTime(day.year, day.month, day.day, hour, half * 30);
        final isHour = half == 0;
        final topLine = isHour ? lineStrong : line;
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
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: brand,
                                  ),
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
                            color: lineStrong,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(width: 1.5, color: lineStrong),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: topLine, width: isHour ? 1.25 : 1),
                        ),
                      ),
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      child: Text(
                        DateFormat.Hm().format(slotStart),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: brand.withValues(alpha: 0.55),
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
    final muted = item.isCompleted;
    final surface = Theme.of(context).colorScheme.surface;
    final blockColor = muted
        ? Color.lerp(fill, surface, 0.35)!
        : fill;
    final onFill = blockColor.computeLuminance() > 0.55
        ? const Color(0xFF3D3D3D)
        : Colors.white;

    final timeLabel =
        '${DateFormat.jm().format(item.start)} - ${DateFormat.jm().format(item.end)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: blockColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: fill.withValues(alpha: muted ? 0.55 : 1),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: onFill.withValues(alpha: 0.9),
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
                                    height: 1.05,
                                    fontSize: 12.5,
                                    decoration: muted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: onFill.withValues(
                                      alpha: muted ? 0.75 : 1,
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
                                    height: 1.05,
                                    fontSize: 10.5,
                                    color: onFill.withValues(alpha: 0.8),
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
