import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/task_categories.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/utils/date_filters.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/category_chip_selector.dart';
import '../../../../shared/widgets/category_label.dart';
import '../../../../shared/widgets/gold_checkbox.dart';
import '../../../../shared/widgets/list_tile_trailing.dart';
import '../../../../shared/widgets/private_content_gate.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../../shared/widgets/voice_play_button.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../domain/entities/task.dart';
import '../widgets/task_form_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({
    super.key,
    this.createdToday = false,
    this.initialFilter,
  });

  final bool createdToday;
  /// `pinned`, `pending`, `completed`, `private`, `archived`, or null/all.
  final String? initialFilter;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _query = '';
  String _sort = 'updated';
  String _statusFilter = 'all';
  String? _categoryFilter;
  late bool _createdToday;

  @override
  void initState() {
    super.initState();
    _createdToday = widget.createdToday;
    _applyInitialFilter(widget.initialFilter);
  }

  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.createdToday != widget.createdToday) {
      _createdToday = widget.createdToday;
    }
    if (oldWidget.initialFilter != widget.initialFilter) {
      _applyInitialFilter(widget.initialFilter);
    }
  }

  void _applyInitialFilter(String? filter) {
    if (filter == null || filter.isEmpty) return;
    if (filter == 'createdToday') {
      _createdToday = true;
      _statusFilter = 'all';
      return;
    }
    _statusFilter = filter;
    if (filter != 'all') _createdToday = false;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(_tasksListProvider);
    final custom = ref.watch(customTaskCategoriesProvider);
    final overrides = ref.watch(defaultCategoryColorsProvider);
    final used = (tasksAsync.valueOrNull ?? const <Task>[])
        .map((t) => t.category);
    final categories = TaskCategories.ordered(
      custom: custom,
      usedLabels: used,
      defaultOverrides: overrides,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<String>(
            icon: const SkyIcon(SkyIcons.sort),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'updated', child: Text('Recently updated')),
              PopupMenuItem(value: 'due', child: Text('Due date')),
              PopupMenuItem(value: 'priority', child: Text('Priority')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const SkyIcon(SkyIcons.filter),
            onSelected: (v) => setState(() {
              if (v == 'createdToday') {
                _createdToday = true;
                _statusFilter = 'all';
              } else {
                _statusFilter = v;
                if (v != 'all') _createdToday = false;
              }
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('All active')),
              PopupMenuItem(value: 'createdToday', child: Text('Created today')),
              PopupMenuItem(value: 'pinned', child: Text('Pinned')),
              PopupMenuItem(value: 'pending', child: Text('Pending')),
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
          if (_createdToday)
            Material(
              color: AppColors.brandSecondary(context).withValues(alpha: 0.15),
              child: ListTile(
                dense: true,
                leading: SkyIcon(
                  SkyIcons.today,
                  color: AppColors.brandSecondary(context),
                ),
                title: const Text('Showing items created today'),
                trailing: TextButton(
                  onPressed: () => setState(() => _createdToday = false),
                  child: const Text('Clear'),
                ),
              ),
            ),
          if (_statusFilter == 'pinned' ||
              _statusFilter == 'pending' ||
              _statusFilter == 'private')
            Material(
              color: AppColors.brand(context).withValues(alpha: 0.08),
              child: ListTile(
                dense: true,
                leading: SkyIcon(
                  switch (_statusFilter) {
                    'pinned' => SkyIcons.pin,
                    'pending' => SkyIcons.pending,
                    _ => SkyIcons.private,
                  },
                  color: AppColors.brand(context),
                ),
                title: Text(switch (_statusFilter) {
                  'pinned' => 'Showing pinned tasks',
                  'pending' => 'Showing pending tasks',
                  _ => 'Showing private tasks',
                }),
                trailing: TextButton(
                  onPressed: () => setState(() => _statusFilter = 'all'),
                  child: const Text('Clear'),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Search tasks...',
              onChanged: (v) => setState(() => _query = v),
              leading: const SkyIcon(SkyIcons.search),
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
                ...categories.map(
                  (category) => _CategoryChip(
                    label: category.name,
                    color: category.color,
                    selected: _categoryFilter?.toLowerCase() ==
                        category.name.toLowerCase(),
                    onTap: () =>
                        setState(() => _categoryFilter = category.name),
                    onLongPress: () => showCategoryManageSheet(
                      context: context,
                      ref: ref,
                      category: category,
                      currentSelection: _categoryFilter ?? '',
                      onDeletedOrRenamed: (next) {
                        setState(() {
                          if (_categoryFilter?.toLowerCase() ==
                              category.name.toLowerCase()) {
                            _categoryFilter = next;
                          }
                        });
                      },
                    ),
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
                  return const Center(
                    child: Text('No tasks found. Tap Create to add one.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return _TaskCard(
                      task: task,
                      onTap: () => showTaskFormSheet(context, ref, task: task),
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
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    if (_createdToday) {
      result = result
          .where((t) => DateFilters.isCreatedToday(t.createdAt))
          .toList();
    }
    if (_categoryFilter != null) {
      final filter = _categoryFilter!.toLowerCase();
      result = result
          .where((t) => t.category.toLowerCase() == filter)
          .toList();
    }
    return switch (_statusFilter) {
      'pinned' => result.where((t) => t.pinned && !t.archived).toList(),
      'pending' =>
        result.where((t) => !t.completed && !t.archived).toList(),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? color;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final fill = color != null ? Color(color!) : null;
    final onFill = fill != null && fill.computeLuminance() > 0.55
        ? const Color(0xFF3D3D3D)
        : (fill != null ? Colors.white : null);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: FilterChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onTap(),
          selectedColor: fill ?? AppColors.brand(context).withValues(alpha: 0.25),
          backgroundColor: fill?.withValues(alpha: 0.45) ??
              Theme.of(context).colorScheme.surface,
          side: BorderSide(
            color: selected
                ? (fill ?? AppColors.brand(context))
                : (fill?.withValues(alpha: 0.7) ??
                    AppColors.brand(context).withValues(alpha: 0.25)),
          ),
          labelStyle: TextStyle(
            color: selected
                ? (onFill ?? Theme.of(context).colorScheme.onSurface)
                : (onFill?.withValues(alpha: 0.85) ??
                    Theme.of(context).colorScheme.onSurface),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
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
    final meta = [
      if (task.dueDate != null)
        'Due ${DateFormat.MMMd().format(task.dueDate!)}',
      if (task.isVoice) 'Voice',
    ].join(' • ');

    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          decoration: task.completed ? TextDecoration.lineThrough : null,
          height: 1.15,
          fontWeight: FontWeight.w500,
        );
    final subtitleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        );

    return AnimatedOpacity(
      opacity: task.completed ? 0.6 : 1,
      duration: const Duration(milliseconds: 300),
      child: Card(
        margin: const EdgeInsets.only(bottom: 4),
        child: PrivateContentGate(
          isPrivate: task.isPrivate,
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            minVerticalPadding: 4,
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
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  CategoryLabel(task.category),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meta,
                        style: subtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: ListTileTrailing(
              children: [
                if (task.isVoice && task.voicePath != null)
                  VoicePlayButton(path: task.voicePath!),
                if (task.pinned) const SkyIcon(SkyIcons.pin, size: 18),
                if (task.archived)
                  const SkyIcon(SkyIcons.archive, size: 18),
                const SkyIcon(SkyIcons.chevronRight, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
