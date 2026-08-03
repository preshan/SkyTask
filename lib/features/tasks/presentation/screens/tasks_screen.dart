import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/gold_checkbox.dart';
import '../../../../shared/widgets/private_content_gate.dart';
import '../../../../shared/widgets/voice_play_button.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../domain/entities/task.dart';
import '../widgets/task_form_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _query = '';
  String _sort = 'updated';
  String _statusFilter = 'all';
  TaskCategory? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(_tasksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'updated', child: Text('Recently updated')),
              PopupMenuItem(value: 'due', child: Text('Due date')),
              PopupMenuItem(value: 'priority', child: Text('Priority')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _statusFilter = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('All active')),
              PopupMenuItem(value: 'pinned', child: Text('Pinned')),
              PopupMenuItem(value: 'completed', child: Text('Completed')),
              PopupMenuItem(value: 'private', child: Text('Private')),
              PopupMenuItem(value: 'archived', child: Text('Archived')),
            ],
          ),
          ...skyTaskAppBarActions(context),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Search tasks...',
              onChanged: (v) => setState(() => _query = v),
              leading: const Icon(Icons.search),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _categoryFilter == null,
                  onTap: () => setState(() => _categoryFilter = null),
                ),
                ...TaskCategory.values.map(
                  (category) => _CategoryChip(
                    label: _categoryLabel(category),
                    selected: _categoryFilter == category,
                    onTap: () => setState(() => _categoryFilter = category),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (tasks) {
                var filtered = _applyFilters(tasks);
                filtered = _applySort(filtered);

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No tasks found.\nTap Create to add one.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TaskCard(
                        task: task,
                        onTap: () =>
                            showTaskFormSheet(context, ref, task: task),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Task> _applyFilters(List<Task> tasks) {
    var result = tasks;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    if (_categoryFilter != null) {
      result = result.where((t) => t.category == _categoryFilter).toList();
    }
    return switch (_statusFilter) {
      'pinned' => result.where((t) => t.pinned && !t.archived).toList(),
      'completed' => result.where((t) => t.completed).toList(),
      'private' => result.where((t) => t.isPrivate).toList(),
      'archived' => result.where((t) => t.archived).toList(),
      _ => result.where((t) => !t.archived).toList(),
    };
  }

  List<Task> _applySort(List<Task> tasks) {
    final copy = List<Task>.from(tasks);
    switch (_sort) {
      case 'due':
        copy.sort((a, b) =>
            (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999)));
      case 'priority':
        copy.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      default:
        copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return copy;
  }
}

final _tasksListProvider = FutureProvider<List<Task>>((ref) async {
  ref.watch(tasksRevisionProvider);
  final repo = await ref.read(taskRepositoryProvider.future);
  return repo.getAll(includeArchived: true);
});

String _categoryLabel(TaskCategory category) {
  final name = category.name;
  return '${name[0].toUpperCase()}${name.substring(1)}';
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.brand(context).withValues(alpha: 0.25),
        backgroundColor: Theme.of(context).colorScheme.surface,
        side: BorderSide(
          color: selected ? AppColors.brand(context) : AppColors.brand(context).withValues(alpha: 0.25),
        ),
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = [
      _categoryLabel(task.category),
      if (task.dueDate != null)
        'Due ${DateFormat.MMMd().format(task.dueDate!)}',
      if (task.isVoice) 'Voice',
    ].join(' • ');

    return AnimatedOpacity(
      opacity: task.completed ? 0.6 : 1,
      duration: const Duration(milliseconds: 300),
      child: Card(
        child: PrivateContentGate(
          isPrivate: task.isPrivate,
          child: ListTile(
            onTap: onTap,
            leading: GoldCheckbox(
              value: task.completed,
              onChanged: (_) async {
                final repo = await ref.read(taskRepositoryProvider.future);
                await repo.toggleComplete(task.id);
                refreshTasks(ref);
              },
            ),
            title: Text(
              displayItemTitle(
                title: task.title,
                isVoice: task.isVoice,
                createdAt: task.createdAt,
              ),
              style: task.completed
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.isVoice && task.voicePath != null)
                  VoicePlayButton(path: task.voicePath!),
                if (task.pinned) const Icon(Icons.push_pin, size: 18),
                if (task.archived)
                  const Icon(Icons.inventory_2_outlined, size: 18),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
