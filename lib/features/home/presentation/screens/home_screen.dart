import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/task_categories.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../core/utils/date_filters.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/async_error_view.dart';
import '../../../../shared/widgets/content_list_card.dart';
import '../../../../shared/widgets/private_content_gate.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../reminders/domain/entities/reminder.dart';
import '../../../reminders/presentation/widgets/reminder_form_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekRemindersAsync = ref.watch(_thisWeekReminderDaysProvider);
    final recentAsync = ref.watch(_recentRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkyTask'),
        actions: skyTaskAppBarActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _GreetingHeader(),
          const SizedBox(height: 16),
          const _HomeActionCards(),
          _HomeSectionHeader(
            title: 'Today',
            onSeeAll: () => context.go(AppRoutes.calendar),
          ),
          weekRemindersAsync.when(
            loading: () => const _ShimmerCard(height: 88),
            error: (e, _) => AsyncErrorView(
              error: e,
              compact: true,
              onRetry: () => ref.invalidate(_thisWeekReminderDaysProvider),
            ),
            data: (days) => _TodayDayStrip(days: days),
          ),
          const _HomeSectionHeader(title: 'Shortcuts'),
          const _HomeShortcuts(),
          _HomeSectionHeader(
            title: 'Recent reminders',
            onSeeAll: () => context.go(AppRoutes.calendar),
          ),
          recentAsync.when(
            loading: () => const _ShimmerCard(height: 120),
            error: (e, _) => AsyncErrorView(
              error: e,
              compact: true,
              onRetry: () => ref.invalidate(_recentRemindersProvider),
            ),
            data: (reminders) => _RecentRemindersCard(reminders: reminders),
          ),
        ],
      ),
    );
  }
}

final _thisWeekReminderDaysProvider =
    FutureProvider<List<_WeekDayReminders>>((ref) async {
  ref.watch(remindersRevisionProvider);
  final repo = await ref.watch(reminderRepositoryProvider.future);
  final all = await repo.getAll();

  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day)
      .subtract(const Duration(days: 1));

  return List.generate(7, (i) {
    final day = start.add(Duration(days: i));
    final count = all.where((r) {
      if (r.isCompleted) return false;
      return DateFilters.isSameDay(r.reminderDateTime, day);
    }).length;
    return _WeekDayReminders(day: day, count: count);
  });
});

final _recentRemindersProvider = FutureProvider<List<Reminder>>((ref) async {
  ref.watch(remindersRevisionProvider);
  final repo = await ref.watch(reminderRepositoryProvider.future);
  final all = await repo.getAll();
  final startOfToday = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  final upcoming = all
      .where((r) => !r.isCompleted && !r.reminderDateTime.isBefore(startOfToday))
      .toList()
    ..sort((a, b) => a.reminderDateTime.compareTo(b.reminderDateTime));

  return upcoming.take(5).toList(growable: false);
});

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

class _WeekDayReminders {
  const _WeekDayReminders({required this.day, required this.count});

  final DateTime day;
  final int count;
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
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Stay organized and make progress ✨',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: muted,
              ),
        ),
      ],
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: brand,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('See all'),
                  const SizedBox(width: 2),
                  SkyIcon(SkyIcons.chevronRight, size: 16, color: brand),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeActionCards extends StatelessWidget {
  const _HomeActionCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionNavCard(
            title: 'Tasks',
            subtitle: 'View and manage your tasks',
            icon: SkyIcons.task,
            background: const Color(0xFFE8EAF6),
            iconBackground: const Color(0xFFC5CAE9),
            iconColor: const Color(0xFF3949AB),
            onTap: () => context.go(AppRoutes.tasks),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionNavCard(
            title: 'Reminders',
            subtitle: 'Never miss important things',
            icon: SkyIcons.alarm,
            background: const Color(0xFFFFF0E6),
            iconBackground: const Color(0xFFFFCCBC),
            iconColor: const Color(0xFFE65100),
            onTap: () => context.go(AppRoutes.calendarDay(DateTime.now())),
          ),
        ),
      ],
    );
  }
}

class _ActionNavCard extends StatelessWidget {
  const _ActionNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final Color background;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? iconColor.withValues(alpha: 0.18)
        : background;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62);

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? iconColor.withValues(alpha: 0.28)
                          : iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: SkyIcon(icon, size: 22, color: iconColor),
                  ),
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: isDark ? 0.35 : 0.72),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: SkyIcon(
                      SkyIcons.chevronRight,
                      size: 16,
                      color: muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: muted,
                      height: 1.25,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayDayStrip extends StatelessWidget {
  const _TodayDayStrip({required this.days});

  final List<_WeekDayReminders> days;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _WeekDayTile(item: days[i]),
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
    final isToday = DateFilters.isCreatedToday(item.day);
    final weekday = DateFormat.E().format(item.day);
    final dayNum = '${item.day.day}';
    const onSelected = Colors.white;

    return Material(
      color: isToday ? brand : ContentListCard.surfaceColor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.go(AppRoutes.calendarDay(item.day)),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekday,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? onSelected.withValues(alpha: 0.9)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayNum,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? onSelected
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday
                        ? onSelected
                        : item.count > 0
                            ? brand.withValues(alpha: 0.55)
                            : Colors.transparent,
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

class _HomeShortcuts extends ConsumerWidget {
  const _HomeShortcuts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(_shortcutCountsProvider);

    return countsAsync.when(
      loading: () => const _ShimmerCard(height: 160),
      error: (e, _) => AsyncErrorView(
        error: e,
        compact: true,
        onRetry: () => ref.invalidate(_shortcutCountsProvider),
      ),
      data: (counts) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ShortcutTile(
                  title: 'Pinned tasks',
                  subtitle: 'Keep important work close',
                  icon: SkyIcons.pin,
                  iconColor: const Color(0xFF7E57C2),
                  iconBackground: const Color(0xFFEDE7F6),
                  count: counts.pinnedTasks,
                  onTap: () => context.go(AppRoutes.tasksPinned()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShortcutTile(
                  title: 'Pending tasks',
                  subtitle: 'Still waiting on you',
                  icon: SkyIcons.pending,
                  iconColor: const Color(0xFF1E88E5),
                  iconBackground: const Color(0xFFE3F2FD),
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
                  title: 'Private ideas',
                  subtitle: 'Your locked ideas',
                  icon: SkyIcons.private,
                  iconColor: const Color(0xFF43A047),
                  iconBackground: const Color(0xFFE8F5E9),
                  count: counts.privateIdeas,
                  onTap: () => context.go(AppRoutes.ideasPrivate()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShortcutTile(
                  title: 'Private reminders',
                  subtitle: 'Your locked alerts',
                  icon: SkyIcons.alarm,
                  iconColor: const Color(0xFFD81B60),
                  iconBackground: const Color(0xFFFCE4EC),
                  count: counts.privateReminders,
                  onTap: () => context.go(AppRoutes.remindersPrivate()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.count,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final Color iconColor;
  final Color iconBackground;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amber = AppColors.brandSecondary(context);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.62);

    return Material(
      color: ContentListCard.surfaceColor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? iconColor.withValues(alpha: 0.22)
                      : iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: SkyIcon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: muted,
                          ),
                    ),
                  ],
                ),
              ),
              SkyIcon(
                SkyIcons.chevronRight,
                size: 16,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRemindersCard extends ConsumerWidget {
  const _RecentRemindersCard({required this.reminders});

  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reminders.isEmpty) {
      return Material(
        color: ContentListCard.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No upcoming reminders.\nTap Create to add one.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.62),
                ),
          ),
        ),
      );
    }

    final custom = ref.watch(customTaskCategoriesProvider);
    final overrides = ref.watch(defaultCategoryColorsProvider);

    return Material(
      color: ContentListCard.surfaceColor(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < reminders.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 20,
                endIndent: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.08),
              ),
            _RecentReminderRow(
              reminder: reminders[i],
              dotColor: Color(
                TaskCategories.colorFor(
                  reminders[i].category,
                  custom: custom,
                  defaultOverrides: overrides,
                ),
              ),
              onTap: () => showReminderFormSheet(
                context,
                ref,
                reminder: reminders[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentReminderRow extends StatelessWidget {
  const _RecentReminderRow({
    required this.reminder,
    required this.dotColor,
    required this.onTap,
  });

  final Reminder reminder;
  final Color dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62);
    final title = displayItemTitle(
      title: reminder.title,
      isVoice: reminder.isVoice,
      createdAt: reminder.createdAt,
    );
    final subtitle = reminder.description?.trim().isNotEmpty == true
        ? reminder.description!.trim()
        : reminder.isVoice
            ? 'Voice memo'
            : TaskCategories.normalize(reminder.category);
    final dayLabel = _dayLabel(reminder.reminderDateTime);
    final timeLabel = DateFormat.jm().format(reminder.reminderDateTime);

    return PrivateContentGate(
      isPrivate: reminder.isPrivate,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: muted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dayLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: muted,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return DateFormat.MMMd().format(dt);
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({this.height = 80});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ContentListCard.surfaceColor(context),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
