import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../domain/entities/task.dart';

Future<void> showTaskFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Task? task,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _TaskFormSheet(task: task),
    ),
  );
}

class _TaskFormSheet extends ConsumerStatefulWidget {
  const _TaskFormSheet({this.task});

  final Task? task;

  @override
  ConsumerState<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<_TaskFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  late TaskCategory _category;
  late bool _pinned;
  late bool _isPrivate;
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController =
        TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? TaskPriority.medium;
    _category = t?.category ?? TaskCategory.personal;
    _pinned = t?.pinned ?? false;
    _isPrivate = t?.isPrivate ?? false;
    _dueDate = t?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final repo = await ref.read(taskRepositoryProvider.future);
    final description = _descriptionController.text.trim();

    try {
      final task = _isEditing
          ? widget.task!.copyWith(
              title: title,
              description: description.isEmpty ? null : description,
              priority: _priority,
              category: _category,
              dueDate: _dueDate,
              pinned: _pinned,
              isPrivate: _isPrivate,
              updatedAt: now,
            )
          : Task(
              id: const Uuid().v4(),
              title: title,
              description: description.isEmpty ? null : description,
              priority: _priority,
              category: _category,
              dueDate: _dueDate,
              pinned: _pinned,
              isPrivate: _isPrivate,
              createdAt: now,
              updatedAt: now,
            );

      await repo.save(task);
      refreshTasks(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final task = widget.task;
    if (task == null) return;

    final ok = await confirmDelete(context, title: 'Delete task?');
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.delete(task.id);
    refreshTasks(ref);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleComplete() async {
    final task = widget.task;
    if (task == null) return;

    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.toggleComplete(task.id);
    refreshTasks(ref);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _archive() async {
    final task = widget.task;
    if (task == null) return;

    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.save(task.copyWith(archived: true, updatedAt: DateTime.now()));
    refreshTasks(ref);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dueLabel = _dueDate == null
        ? 'No due date'
        : DateFormat.yMMMd().format(_dueDate!);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isEditing ? 'Edit Task' : 'New Task',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskCategory>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: TaskCategory.values
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(_label(c.name)),
                  ),
                )
                .toList(),
            onChanged: _saving ? null : (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskPriority>(
            initialValue: _priority,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
            ),
            items: TaskPriority.values
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(_label(p.name)),
                  ),
                )
                .toList(),
            onChanged: _saving ? null : (v) => setState(() => _priority = v!),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('Due date'),
            subtitle: Text(dueLabel),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_dueDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _saving ? null : () => setState(() => _dueDate = null),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: _saving ? null : _pickDueDate,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pin task'),
            value: _pinned,
            onChanged: _saving ? null : (v) => setState(() => _pinned = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Private task'),
            value: _isPrivate,
            onChanged: _saving ? null : (v) => setState(() => _isPrivate = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Save changes' : 'Create task'),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : _toggleComplete,
              child: Text(
                widget.task!.completed ? 'Mark as active' : 'Mark completed',
              ),
            ),
            OutlinedButton(
              onPressed: _saving ? null : _archive,
              child: const Text('Archive task'),
            ),
            TextButton(
              onPressed: _saving ? null : _delete,
              child: const Text('Delete task'),
            ),
          ],
        ],
      ),
    );
  }

  String _label(String raw) =>
      raw[0].toUpperCase() + raw.substring(1);
}
