import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../notes/domain/entities/note.dart';
import '../../../tasks/domain/entities/task.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_todayTasksProvider);
    final remindersAsync = ref.watch(_upcomingRemindersProvider);
    final ideasAsync = ref.watch(_recentIdeasProvider);
    final notesAsync = ref.watch(_recentNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkyTask'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go(AppRoutes.calendar),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GreetingHeader(),
          const SizedBox(height: 8),
          SectionHeader(
            title: 'Today',
            onAction: () => context.go(AppRoutes.tasks),
          ),
          tasksAsync.when(
            loading: () => const _ShimmerCard(),
            error: (e, _) => Text('Error: $e'),
            data: (tasks) => _TaskSummaryCard(tasks: tasks),
          ),
          SectionHeader(
            title: 'Upcoming Reminders',
            onAction: () => context.go(AppRoutes.calendar),
          ),
          remindersAsync.when(
            loading: () => const _ShimmerCard(),
            error: (e, _) => Text('Error: $e'),
            data: (reminders) {
              if (reminders.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.alarm_outlined),
                    title: Text('No upcoming reminders'),
                  ),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (final r in reminders.take(3))
                      ListTile(
                        leading: const Icon(Icons.alarm, color: AppColors.primary),
                        title: Text(r.title),
                        subtitle: Text(
                          DateFormat.MMMd().add_jm().format(r.reminderDateTime),
                        ),
                      ),
                  ],
                ),
              );
            },
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
                      ListTile(
                        leading: const Icon(Icons.lightbulb_outline),
                        title: Text(
                          idea.isPrivate ? 'Private Item' : idea.title,
                        ),
                        subtitle: idea.isPrivate
                            ? const Text('🔒 Hidden Content')
                            : Text(
                                idea.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                  ],
                ),
              );
            },
          ),
          SectionHeader(
            title: 'Recent Notes',
            onAction: () => context.go(AppRoutes.ideas),
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
                      ListTile(
                        leading: const Icon(Icons.note_outlined),
                        title: Text(
                          note.isPrivate ? 'Private Item' : note.title,
                        ),
                        subtitle: note.isPrivate
                            ? const Text('🔒 Hidden Content')
                            : Text(
                                note.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

final _todayTasksProvider = FutureProvider<List<Task>>((ref) async {
  ref.watch(tasksRevisionProvider);
  final repo = await ref.read(taskRepositoryProvider.future);
  return repo.getToday();
});

final _upcomingRemindersProvider = FutureProvider((ref) async {
  ref.watch(remindersRevisionProvider);
  final repo = await ref.watch(reminderRepositoryProvider.future);
  return repo.getUpcoming();
});

final _recentIdeasProvider = FutureProvider((ref) async {
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

class _TaskSummaryCard extends StatelessWidget {
  const _TaskSummaryCard({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t.completed).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tasks.length} tasks today',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('$completed completed'),
                ],
              ),
            ),
            CircularProgressIndicator(
              value: tasks.isEmpty ? 0 : completed / tasks.length,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              color: AppColors.goldAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard('Pinned', '—', Icons.push_pin_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard('Private', '—', Icons.lock_outline)),
        const SizedBox(width: 12),
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
            Icon(icon, color: AppColors.primary),
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
      child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
    );
  }
}
