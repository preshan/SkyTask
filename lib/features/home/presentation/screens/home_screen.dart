import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../core/utils/date_filters.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/private_content_gate.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../../shared/widgets/voice_play_button.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../notes/domain/entities/note.dart';
import '../../../ideas/domain/entities/idea.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayCountsAsync = ref.watch(_todayCreatedCountsProvider);
    final weekRemindersAsync = ref.watch(_thisWeekReminderDaysProvider);
    final ideasAsync = ref.watch(_recentIdeasProvider);
    final notesAsync = ref.watch(_recentNotesProvider);

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
            title: 'This week',
            onAction: () => context.go(AppRoutes.calendar),
          ),
          weekRemindersAsync.when(
            loading: () => const _ShimmerCard(),
            error: (e, _) => Text('Error: $e'),
            data: (days) => _ThisWeekReminderStrip(days: days),
          ),
          SectionHeader(
            title: 'Recent Ideas',
            onAction: () => context.go(AppRoutes.ideas),
          ),
          ideasAsync.when(
            loading: () => const _ShimmerCard(),
            error: (e, _) => Text('Error: $e'),
            data: (ideas) {
              if (ideas.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.lightbulb_outline),
                    title: Text('Capture your first idea'),
                  ),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (final idea in ideas.take(3))
                      PrivateContentGate(
                        isPrivate: idea.isPrivate,
                        child: ListTile(
                          leading: Icon(
                            idea.isVoice
                                ? Icons.mic
                                : Icons.lightbulb_outline,
                            color: AppColors.brandSecondary(context),
                          ),
                          title: Text(
                            displayItemTitle(
                              title: idea.title,
                              isVoice: idea.isVoice,
                              createdAt: idea.createdAt,
                            ),
                          ),
                          subtitle: Text(
                            idea.isVoice && idea.content.isEmpty
                                ? 'Voice memo'
                                : idea.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: idea.isVoice && idea.voicePath != null
                              ? VoicePlayButton(path: idea.voicePath!)
                              : null,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          SectionHeader(
            title: 'Recent Notes',
            onAction: () => context.go('${AppRoutes.ideas}?tab=notes'),
          ),
          notesAsync.when(
            loading: () => const _ShimmerCard(),
            error: (e, _) => Text('Error: $e'),
            data: (notes) {
              if (notes.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.note_outlined),
                    title: Text('Write your first note'),
                  ),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (final note in notes.take(3))
                      PrivateContentGate(
                        isPrivate: note.isPrivate,
                        child: ListTile(
                          leading: Icon(
                            note.isVoice ? Icons.mic : Icons.note_outlined,
                            color: AppColors.brandSecondary(context),
                          ),
                          title: Text(
                            displayItemTitle(
                              title: note.title,
                              isVoice: note.isVoice,
                              createdAt: note.createdAt,
                            ),
                          ),
                          subtitle: Text(
                            note.isVoice && note.content.isEmpty
                                ? 'Voice memo'
                                : note.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: note.isVoice && note.voicePath != null
                              ? VoicePlayButton(path: note.voicePath!)
                              : null,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SectionHeader(title: 'Productivity'),
          const _StatsRow(),
        ],
      ),
    );
  }
}

class _TodayCounts {
  const _TodayCounts({
    required this.tasks,
    required this.ideas,
    required this.notes,
  });

  final int tasks;
  final int ideas;
  final int notes;
}

final _todayCreatedCountsProvider = FutureProvider<_TodayCounts>((ref) async {
  ref.watch(tasksRevisionProvider);
  ref.watch(ideasRevisionProvider);
  ref.watch(notesRevisionProvider);

  final taskRepo = await ref.read(taskRepositoryProvider.future);
  final ideaRepo = await ref.read(ideaRepositoryProvider.future);
  final noteRepo = await ref.read(noteRepositoryProvider.future);

  final tasks = await taskRepo.getAll();
  final ideas = await ideaRepo.getAll();
  final notes = await noteRepo.getAll();

  return _TodayCounts(
    tasks: tasks.where((t) => DateFilters.isCreatedToday(t.createdAt)).length,
    ideas: ideas.where((i) => DateFilters.isCreatedToday(i.createdAt)).length,
    notes: notes.where((n) => DateFilters.isCreatedToday(n.createdAt)).length,
  );
});

final _thisWeekReminderDaysProvider =
    FutureProvider<List<_WeekDayReminders>>((ref) async {
  ref.watch(remindersRevisionProvider);
  final repo = await ref.watch(reminderRepositoryProvider.future);
  final all = await repo.getAll();

  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - DateTime.monday));

  return List.generate(7, (i) {
    final day = monday.add(Duration(days: i));
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

final _recentIdeasProvider = FutureProvider<List<Idea>>((ref) async {
  ref.watch(ideasRevisionProvider);
  final repo = await ref.read(ideaRepositoryProvider.future);
  final all = await repo.getAll();
  return all.take(5).toList();
});

final _recentNotesProvider = FutureProvider<List<Note>>((ref) async {
  ref.watch(notesRevisionProvider);
  final repo = await ref.read(noteRepositoryProvider.future);
  final all = await repo.getAll();
  return all.take(3).toList();
});

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

    return Material(
      color: isToday
          ? brand.withValues(alpha: 0.10)
          : scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.go(AppRoutes.calendarDay(item.day)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isToday
                  ? brand.withValues(alpha: 0.45)
                  : brand.withValues(alpha: 0.12),
              width: isToday ? 1.5 : 1,
            ),
          ),
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
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.count > 0 ? amber : scheme.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${item.count}',
                    style: TextStyle(
                      color: item.count > 0
                          ? scheme.onSecondary
                          : scheme.onSurface.withValues(alpha: 0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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
              label: 'Ideas',
              count: counts.ideas,
              icon: SkyIcons.lightbulb,
              onTap: () => context.go(AppRoutes.ideasCreatedToday()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TodayTypeTile(
              label: 'Notes',
              count: counts.notes,
              icon: SkyIcons.notes,
              onTap: () => context.go(AppRoutes.notesCreatedToday()),
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

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: brand.withValues(alpha: 0.14)),
          ),
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
                child: Container(
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _StatCard('Pinned', '—', Icons.push_pin_outlined)),
        SizedBox(width: 12),
        Expanded(child: _StatCard('Private', '—', Icons.lock_outline)),
        SizedBox(width: 12),
        Expanded(child: _StatCard('Done', '—', Icons.check_circle_outline)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.brandSecondary(context)),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
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
