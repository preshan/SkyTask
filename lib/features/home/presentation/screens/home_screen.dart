import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/date_filters.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/frosted_surface.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayCountsAsync = ref.watch(_todayCreatedCountsProvider);
    final weekRemindersAsync = ref.watch(_thisWeekReminderDaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkyTask'),
        actions: skyTaskAppBarActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _GreetingHeader(),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Today'),
          todayCountsAsync.when(
            loading: () => const _ShimmerCard(),
            error: (e, _) => Text('Error: $e'),
            data: (counts) => _TodayCreateTiles(counts: counts),
          ),
          SectionHeader(
            title: 'Recent reminders',
            onAction: () => context.go(AppRoutes.calendar),
          ),
          weekRemindersAsync.when(
            loading: () => const _ShimmerCard(),
            error: (e, _) => Text('Error: $e'),
            data: (days) => _ThisWeekReminderStrip(days: days),
          ),
          const SectionHeader(title: 'Shortcuts'),
          const _HomeShortcuts(),
        ],
      ),
    );
  }
}

class _TodayCounts {
  const _TodayCounts({
    required this.tasks,
    required this.reminders,
  });

  final int tasks;
  final int reminders;
}

final _todayCreatedCountsProvider = FutureProvider<_TodayCounts>((ref) async {
  ref.watch(tasksRevisionProvider);
  ref.watch(remindersRevisionProvider);

  final taskRepo = await ref.read(taskRepositoryProvider.future);
  final reminderRepo = await ref.read(reminderRepositoryProvider.future);

  final tasks = await taskRepo.getAll();
  final reminders = await reminderRepo.getAll();
  final today = DateTime.now();

  return _TodayCounts(
    tasks: tasks.where((t) => DateFilters.isCreatedToday(t.createdAt)).length,
    reminders: reminders.where((r) {
      if (r.isCompleted) return false;
      return DateFilters.isSameDay(r.reminderDateTime, today);
    }).length,
  );
});

final _thisWeekReminderDaysProvider =
    FutureProvider<List<_WeekDayReminders>>((ref) async {
  ref.watch(remindersRevisionProvider);
  final repo = await ref.watch(reminderRepositoryProvider.future);
  final all = await repo.getAll();

  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);

  return List.generate(7, (i) {
    final day = start.add(Duration(days: i));
    final count = all.where((r) {
      if (r.isCompleted) return false;
      return DateFilters.isSameDay(r.reminderDateTime, day);
    }).length;
    return _WeekDayReminders(day: day, count: count);
  });
});

class _WeekDayReminders {
  const _WeekDayReminders({required this.day, required this.count});

  final DateTime day;
  final int count;
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Text(
      greeting,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class _ThisWeekReminderStrip extends StatelessWidget {
  const _ThisWeekReminderStrip({required this.days});

  final List<_WeekDayReminders> days;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _WeekDayTile(item: days[i])),
          ],
        ],
      ),
    );
  }
}

class _WeekDayTile extends StatelessWidget {
  const _WeekDayTile({required this.item});

  final _WeekDayReminders item;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    final amber = AppColors.brandSecondary(context);
    final scheme = Theme.of(context).colorScheme;
    final isToday = DateFilters.isCreatedToday(item.day);
    final weekday = DateFormat.E().format(item.day); // Mon
    final dayNum = '${item.day.day}';

    return FrostedSurface(
      borderRadius: 14,
      borderColor: isToday
          ? brand.withValues(alpha: 0.45)
          : null,
      borderWidth: isToday ? 1.5 : 1,
      onTap: () => context.go(AppRoutes.calendarDay(item.day)),
      child: SizedBox(
        height: 88,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekday,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isToday ? brand : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayNum,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isToday ? brand : null,
                        ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: item.count > 0
                  ? Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: amber,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${item.count}',
                        style: TextStyle(
                          color: scheme.onSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCreateTiles extends StatelessWidget {
  const _TodayCreateTiles({required this.counts});

  final _TodayCounts counts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _TodayTypeTile(
              label: 'Tasks',
              count: counts.tasks,
              icon: SkyIcons.task,
              onTap: () => context.go(AppRoutes.tasksCreatedToday()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TodayTypeTile(
              label: 'Reminders',
              count: counts.reminders,
              icon: SkyIcons.alarm,
              onTap: () => context.go(AppRoutes.calendarDay(DateTime.now())),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayTypeTile extends StatelessWidget {
  const _TodayTypeTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final List<List<dynamic>> icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    final amber = AppColors.brandSecondary(context);
    final scheme = Theme.of(context).colorScheme;

    return FrostedSurface(
      borderRadius: 16,
      onTap: onTap,
      child: SizedBox(
        height: 96,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkyIcon(icon, size: 28, color: brand),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: count > 0
                  ? Container(
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: amber,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: amber.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: TextStyle(
                          color: scheme.onSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCounts {
  const _ShortcutCounts({
    required this.pinnedTasks,
    required this.pendingTasks,
    required this.privateIdeas,
    required this.privateReminders,
  });

  final int pinnedTasks;
  final int pendingTasks;
  final int privateIdeas;
  final int privateReminders;
}

final _shortcutCountsProvider = FutureProvider<_ShortcutCounts>((ref) async {
  ref.watch(tasksRevisionProvider);
  ref.watch(ideasRevisionProvider);
  ref.watch(remindersRevisionProvider);

  final taskRepo = await ref.read(taskRepositoryProvider.future);
  final ideaRepo = await ref.read(ideaRepositoryProvider.future);
  final reminderRepo = await ref.read(reminderRepositoryProvider.future);

  final tasks = await taskRepo.getAll(includeArchived: true);
  final ideas = await ideaRepo.getAll();
  final reminders = await reminderRepo.getAll();

  return _ShortcutCounts(
    pinnedTasks: tasks.where((t) => t.pinned && !t.archived).length,
    pendingTasks: tasks.where((t) => !t.completed && !t.archived).length,
    privateIdeas: ideas.where((i) => i.isPrivate).length,
    privateReminders:
        reminders.where((r) => r.isPrivate && !r.isCompleted).length,
  );
});

class _HomeShortcuts extends ConsumerWidget {
  const _HomeShortcuts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(_shortcutCountsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      child: countsAsync.when(
        loading: () => const _ShimmerCard(),
        error: (e, _) => Text('Error: $e'),
        data: (counts) => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ShortcutTile(
                    label: 'Pinned tasks',
                    icon: SkyIcons.pin,
                    count: counts.pinnedTasks,
                    onTap: () => context.go(AppRoutes.tasksPinned()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShortcutTile(
                    label: 'Pending tasks',
                    icon: SkyIcons.pending,
                    count: counts.pendingTasks,
                    onTap: () => context.go(AppRoutes.tasksPending()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ShortcutTile(
                    label: 'Private ideas',
                    icon: SkyIcons.private,
                    count: counts.privateIdeas,
                    onTap: () => context.go(AppRoutes.ideasPrivate()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShortcutTile(
                    label: 'Private reminders',
                    icon: SkyIcons.alarm,
                    count: counts.privateReminders,
                    onTap: () => context.go(AppRoutes.remindersPrivate()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final String label;
  final List<List<dynamic>> icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    final amber = AppColors.brandSecondary(context);
    final scheme = Theme.of(context).colorScheme;

    return FrostedSurface(
      borderRadius: 16,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      child: SizedBox(
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: brand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: SkyIcon(icon, size: 24, color: brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 22,
                  minHeight: 22,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: amber,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    color: scheme.onSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
