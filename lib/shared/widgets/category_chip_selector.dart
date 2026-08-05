import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/task_categories.dart';
import '../../core/di/content_providers.dart';
import '../../core/di/providers.dart';
import '../../features/calendar/presentation/providers/calendar_providers.dart';
import 'sky_icon.dart';

/// Shared Work / Personal / custom category chips used by all content forms.
class CategoryChipSelector extends ConsumerWidget {
  const CategoryChipSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_CategoryEditResult>(
      context: context,
      builder: (ctx) => _CategoryEditDialog(
        title: 'New category',
        initialColor: TaskCategories.randomPastel(
          avoid: ref.read(customTaskCategoriesProvider).map((c) => c.color),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final normalized = TaskCategories.normalize(result.name);
    if (normalized.isEmpty) return;
    await ref
        .read(customTaskCategoriesProvider.notifier)
        .add(normalized, color: result.color);
    onChanged(normalized);
  }

  Future<void> _onLongPress(
    BuildContext context,
    WidgetRef ref,
    AppCategory category,
  ) async {
    if (!enabled) return;
    await showCategoryManageSheet(
      context: context,
      ref: ref,
      category: category,
      onDeletedOrRenamed: (nextSelected) {
        if (nextSelected != null) onChanged(nextSelected);
      },
      currentSelection: value,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(customTaskCategoriesProvider);
    final overrides = ref.watch(defaultCategoryColorsProvider);
    final used =
        ref.watch(categoryUsageLabelsProvider).valueOrNull ?? const <String>[];
    final categories = TaskCategories.ordered(
      custom: custom,
      usedLabels: used,
      defaultOverrides: overrides,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Category', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == categories.length) {
                return FilterChip(
                  avatar: SkyIcon(
                    SkyIcons.add,
                    size: 16,
                    color: AppColors.brand(context),
                  ),
                  label: const Text('Add'),
                  selected: false,
                  showCheckmark: false,
                  onSelected: enabled ? (_) => _addCategory(context, ref) : null,
                  side: BorderSide(
                    color: AppColors.brand(context).withValues(alpha: 0.35),
                  ),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }
              final category = categories[index];
              final selected =
                  value.toLowerCase() == category.name.toLowerCase();
              final fill = category.swatch;
              final onFill = _contrastOnPastel(fill);
              return GestureDetector(
                onLongPress: () => _onLongPress(context, ref, category),
                child: FilterChip(
                  label: Text(category.name),
                  selected: selected,
                  showCheckmark: false,
                  onSelected:
                      enabled ? (_) => onChanged(category.name) : null,
                  selectedColor: fill,
                  backgroundColor: fill.withValues(alpha: 0.45),
                  side: BorderSide(
                    color: selected ? fill : fill.withValues(alpha: 0.7),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? onFill : onFill.withValues(alpha: 0.85),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Color _contrastOnPastel(Color fill) {
  return fill.computeLuminance() > 0.55
      ? const Color(0xFF3D3D3D)
      : Colors.white;
}

class _CategoryEditResult {
  const _CategoryEditResult({required this.name, required this.color});
  final String name;
  final int color;
}

/// Long-press manage sheet for edit / delete (shared with tasks filter chips).
Future<void> showCategoryManageSheet({
  required BuildContext context,
  required WidgetRef ref,
  required AppCategory category,
  required String currentSelection,
  required void Function(String? nextSelected) onDeletedOrRenamed,
}) async {
  final isDefault = TaskCategories.isDefault(category.name);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: category.swatch,
                radius: 12,
              ),
              title: Text(category.name),
              subtitle: Text(
                isDefault
                    ? 'Built-in category · long-press actions'
                    : 'Custom category',
              ),
            ),
            ListTile(
              leading: const SkyIcon(SkyIcons.edit),
              title: Text(isDefault ? 'Change color' : 'Edit'),
              onTap: () async {
                Navigator.pop(ctx);
                await _editCategory(
                  context: context,
                  ref: ref,
                  category: category,
                  onDeletedOrRenamed: onDeletedOrRenamed,
                  currentSelection: currentSelection,
                );
              },
            ),
            if (!isDefault)
              ListTile(
                leading: SkyIcon(
                  SkyIcons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _deleteCategory(
                    context: context,
                    ref: ref,
                    category: category,
                    onDeletedOrRenamed: onDeletedOrRenamed,
                    currentSelection: currentSelection,
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> _editCategory({
  required BuildContext context,
  required WidgetRef ref,
  required AppCategory category,
  required String currentSelection,
  required void Function(String? nextSelected) onDeletedOrRenamed,
}) async {
  final isDefault = TaskCategories.isDefault(category.name);
  final result = await showDialog<_CategoryEditResult>(
    context: context,
    builder: (ctx) => _CategoryEditDialog(
      title: isDefault ? 'Edit ${category.name}' : 'Edit category',
      initialName: category.name,
      initialColor: category.color,
      nameLocked: isDefault,
    ),
  );
  if (result == null || !context.mounted) return;

  if (isDefault) {
    await ref
        .read(defaultCategoryColorsProvider.notifier)
        .setColor(category.name, result.color);
    return;
  }

  final newName = TaskCategories.normalize(result.name);
  final oldName = category.name;
  if (newName.isEmpty) return;

  if (newName.toLowerCase() != oldName.toLowerCase()) {
    final taskRepo = await ref.read(taskRepositoryProvider.future);
    final reminderRepo = await ref.read(reminderRepositoryProvider.future);
    final ideaRepo = await ref.read(ideaRepositoryProvider.future);
    final noteRepo = await ref.read(noteRepositoryProvider.future);
    await reassignCategoryAcrossContent(
      from: oldName,
      to: newName,
      tasks: taskRepo,
      reminders: reminderRepo,
      ideas: ideaRepo,
      notes: noteRepo,
    );
    refreshTasks(ref);
    refreshReminders(ref);
    refreshIdeas(ref);
    refreshNotes(ref);
  }

  await ref.read(customTaskCategoriesProvider.notifier).update(
        oldName: oldName,
        name: newName,
        color: result.color,
      );

  if (currentSelection.toLowerCase() == oldName.toLowerCase()) {
    onDeletedOrRenamed(newName);
  }
}

Future<void> _deleteCategory({
  required BuildContext context,
  required WidgetRef ref,
  required AppCategory category,
  required String currentSelection,
  required void Function(String? nextSelected) onDeletedOrRenamed,
}) async {
  final taskRepo = await ref.read(taskRepositoryProvider.future);
  final reminderRepo = await ref.read(reminderRepositoryProvider.future);
  final ideaRepo = await ref.read(ideaRepositoryProvider.future);
  final noteRepo = await ref.read(noteRepositoryProvider.future);

  final count = await countItemsWithCategory(
    category: category.name,
    tasks: taskRepo,
    reminders: reminderRepo,
    ideas: ideaRepo,
    notes: noteRepo,
  );

  if (!context.mounted) return;

  var replacement = TaskCategories.personal;
  if (count > 0) {
    final custom = ref.read(customTaskCategoriesProvider);
    final overrides = ref.read(defaultCategoryColorsProvider);
    final options = TaskCategories.ordered(
      custom: custom,
      usedLabels: const [],
      defaultOverrides: overrides,
    )
        .where((c) => c.name.toLowerCase() != category.name.toLowerCase())
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Delete category?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$count item${count == 1 ? '' : 's'} use “${category.name}”. '
                    'Move them to:',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: replacement,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Move to',
                    ),
                    items: options
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => replacement = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Move & delete'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    await reassignCategoryAcrossContent(
      from: category.name,
      to: replacement,
      tasks: taskRepo,
      reminders: reminderRepo,
      ideas: ideaRepo,
      notes: noteRepo,
    );
    refreshTasks(ref);
    refreshReminders(ref);
    refreshIdeas(ref);
    refreshNotes(ref);
  } else {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Remove “${category.name}” from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
  }

  await ref.read(customTaskCategoriesProvider.notifier).remove(category.name);

  if (currentSelection.toLowerCase() == category.name.toLowerCase()) {
    onDeletedOrRenamed(count > 0 ? replacement : TaskCategories.personal);
  } else {
    onDeletedOrRenamed(null);
  }
}

class _CategoryEditDialog extends StatefulWidget {
  const _CategoryEditDialog({
    required this.title,
    this.initialName = '',
    required this.initialColor,
    this.nameLocked = false,
  });

  final String title;
  final String initialName;
  final int initialColor;
  final bool nameLocked;

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  late final TextEditingController _controller;
  late int _color;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _color = widget.initialColor;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      _CategoryEditResult(name: _controller.text, color: _color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.nameLocked)
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Health, Study',
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
                onSubmitted: (_) => _submit(),
              )
            else
              Text(
                widget.initialName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pastel in TaskCategories.pastelPalette)
                  GestureDetector(
                    onTap: () => setState(() => _color = pastel),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(pastel),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == pastel
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.black26,
                          width: _color == pastel ? 2.5 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.nameLocked ? 'Save' : 'Save'),
        ),
      ],
    );
  }
}
