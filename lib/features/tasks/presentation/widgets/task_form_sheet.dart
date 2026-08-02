import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../../shared/widgets/icon_toggle.dart';
import '../../../../shared/widgets/private_icon_toggle.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../../shared/widgets/voice_memo_recorder.dart';
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
  late final FocusNode _descriptionFocus;
  late TaskPriority _priority;
  late TaskCategory _category;
  late bool _pinned;
  late bool _isPrivate;
  DateTime? _dueDate;
  String? _voicePath;
  final _voiceController = VoiceMemoController();
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    final initialTitle = (t != null &&
            t.isVoice &&
            VoiceMemoService.isPlaceholderTitle(t.title))
        ? ''
        : (t?.title ?? '');
    _titleController = TextEditingController(text: initialTitle);
    _descriptionController =
        TextEditingController(text: t?.description ?? '');
    _descriptionFocus = FocusNode();
    _priority = t?.priority ?? TaskPriority.medium;
    _category = t?.category ?? TaskCategory.personal;
    _pinned = t?.pinned ?? false;
    _isPrivate = t?.isPrivate ?? false;
    _dueDate = t?.dueDate;
    _voicePath = t?.voicePath;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _descriptionFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _descriptionFocus.dispose();
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
    setState(() => _saving = true);
    final now = DateTime.now();
    final voicePath = await _voiceController.finalize() ?? _voicePath;
    _voicePath = voicePath;

    final repo = await ref.read(taskRepositoryProvider.future);
    final description = _descriptionController.text.trim();
    final hasVoice = VoiceMemoService.hasVoice(voicePath);
    final title = voiceAwareTitle(
      rawTitle: _titleController.text,
      hasVoice: hasVoice,
      untitledFallback: 'Untitled task',
      at: _isEditing ? widget.task!.createdAt : now,
    );

    try {
      final previousVoice =
          _isEditing ? widget.task!.voicePath : null;

      final task = _isEditing
          ? widget.task!.copyWith(
              title: title,
              description: description.isEmpty ? null : description,
              priority: _priority,
              category: _category,
              dueDate: _dueDate,
              pinned: _pinned,
              isPrivate: _isPrivate,
              voicePath: voicePath,
              clearVoicePath: voicePath == null,
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
              voicePath: voicePath,
              createdAt: now,
              updatedAt: now,
            );

      await repo.save(task);
      if (previousVoice != null && previousVoice != voicePath) {
        await VoiceMemoService.deleteIfExists(previousVoice);
      }
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
    final dueTooltip = _dueDate == null
        ? 'Set due date'
        : 'Due ${DateFormat.yMMMd().format(_dueDate!)} · long-press to clear';

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
              labelText: 'Title (optional)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _descriptionFocus.requestFocus(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: TaskCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = TaskCategory.values[index];
                final selected = _category == category;
                return FilterChip(
                  label: Text(_label(category.name)),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => _category = category),
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
                  ),
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('Priority', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: TaskPriority.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final priority = TaskPriority.values[index];
                final selected = _priority == priority;
                final color = _priorityColor(priority);
                return FilterChip(
                  label: Text(_label(priority.name)),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => _priority = priority),
                  selectedColor: color.withValues(alpha: 0.25),
                  side: BorderSide(
                    color: selected
                        ? color
                        : AppColors.primary.withValues(alpha: 0.25),
                  ),
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconToggle(
                active: _dueDate != null,
                tooltip: dueTooltip,
                onTap: _saving ? null : _pickDueDate,
                onLongPress: _saving || _dueDate == null
                    ? null
                    : () => setState(() => _dueDate = null),
                child: SkyIcon(
                  SkyIcons.calendar,
                  color: _dueDate != null
                      ? AppColors.primary
                      : AppColors.primaryText,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              IconToggle(
                active: _pinned,
                tooltip: _pinned ? 'Unpin' : 'Pin',
                onTap: _saving
                    ? null
                    : () => setState(() => _pinned = !_pinned),
                child: SkyIcon(
                  SkyIcons.pin,
                  color: _pinned ? AppColors.primary : AppColors.primaryText,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              PrivateIconToggle(
                value: _isPrivate,
                enabled: !_saving,
                onChanged: (v) => setState(() => _isPrivate = v),
              ),
              if (_dueDate != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat.MMMd().format(_dueDate!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryText,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          VoiceMemoRecorder(
            controller: _voiceController,
            initialPath: widget.task?.voicePath,
            enabled: !_saving,
            onChanged: (path) => setState(() => _voicePath = path),
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

  String _label(String raw) => raw[0].toUpperCase() + raw.substring(1);

  Color _priorityColor(TaskPriority priority) => switch (priority) {
        TaskPriority.low => AppColors.success,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.high => AppColors.error,
      };
}
