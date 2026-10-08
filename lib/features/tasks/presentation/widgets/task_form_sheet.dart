import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/task_categories.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/constants/capture_preference.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../shared/widgets/category_chip_selector.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../../shared/widgets/form_action_button.dart';
import '../../../../shared/widgets/form_quick_action_tile.dart';
import '../../../../shared/widgets/form_sheet_header.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../../shared/widgets/voice_memo_recorder.dart';
import '../../domain/entities/task.dart';

Future<void> showTaskFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Task? task,
  DateTime? initialDateTime,
  int? planDurationMinutes,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _TaskFormSheet(
        task: task,
        initialDateTime: initialDateTime,
        planDurationMinutes: planDurationMinutes,
      ),
    ),
  );
}

class _TaskFormSheet extends ConsumerStatefulWidget {
  const _TaskFormSheet({
    this.task,
    this.initialDateTime,
    this.planDurationMinutes,
  });

  final Task? task;
  final DateTime? initialDateTime;
  final int? planDurationMinutes;

  @override
  ConsumerState<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<_TaskFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final FocusNode _descriptionFocus;
  late TaskPriority _priority;
  late String _category;
  late bool _pinned;
  late bool _isPrivate;
  DateTime? _dueDate;
  int? _dueTimeMinutes;
  late int _durationMinutes;
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
    _category = TaskCategories.normalize(t?.category ?? TaskCategories.personal);
    _pinned = t?.pinned ?? false;
    _isPrivate = t?.isPrivate ?? false;
    _durationMinutes =
        t?.durationMinutes ?? widget.planDurationMinutes ?? 30;
    _voicePath = t?.voicePath;

    if (t != null) {
      _dueDate = t.dueDate;
      _dueTimeMinutes = t.dueTimeMinutes;
    } else if (widget.initialDateTime != null) {
      final dt = widget.initialDateTime!;
      _dueDate = DateTime(dt.year, dt.month, dt.day);
      _dueTimeMinutes = dt.hour * 60 + dt.minute;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(preferVoiceCaptureProvider)) {
        _descriptionFocus.requestFocus();
      }
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
    setState(() => _dueDate = DateTime(date.year, date.month, date.day));
  }

  Future<void> _pickDueTime() async {
    final initial = _dueTimeMinutes != null
        ? TimeOfDay(hour: _dueTimeMinutes! ~/ 60, minute: _dueTimeMinutes! % 60)
        : TimeOfDay.now();
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time == null || !mounted) return;
    setState(() {
      _dueDate ??= DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      _dueTimeMinutes = time.hour * 60 + time.minute;
    });
  }

  String _formatDueLabel() {
    if (_dueDate == null) return 'Due date';
    final date = DateFormat.yMMMd().format(_dueDate!);
    if (_dueTimeMinutes == null) return date;
    final h = _dueTimeMinutes! ~/ 60;
    final m = _dueTimeMinutes! % 60;
    final time = DateFormat.jm().format(DateTime(2000, 1, 1, h, m));
    return '$date · $time';
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
      final dueTime =
          _dueDate == null ? null : _dueTimeMinutes;

      final task = _isEditing
          ? widget.task!.copyWith(
              title: title,
              description: description.isEmpty ? null : description,
              priority: _priority,
              category: _category,
              dueDate: _dueDate,
              clearDueDate: _dueDate == null,
              dueTimeMinutes: dueTime,
              clearDueTimeMinutes: dueTime == null,
              durationMinutes: _durationMinutes,
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
              dueTimeMinutes: dueTime,
              durationMinutes: _durationMinutes,
              pinned: _pinned,
              isPrivate: _isPrivate,
              voicePath: voicePath,
              createdAt: now,
              updatedAt: now,
            );

      await repo.save(task);
      await ref.read(preferVoiceCaptureProvider.notifier).recordSave(
        hasVoice: hasVoice,
        hasTypedBody: description.isNotEmpty,
      );
      // Persist non-default categories so they stay in the catalog.
      if (!TaskCategories.isDefault(task.category)) {
        await ref.read(customTaskCategoriesProvider.notifier).add(task.category);
      }
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
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    final brand = AppColors.brand(context);
    final dueTooltip = _dueDate == null
        ? 'Set due date'
        : '${_formatDueLabel()} · long-press to clear';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FormSheetHeader(_isEditing ? 'Edit Task' : 'New Task'),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _descriptionFocus.requestFocus(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            autofocus: !ref.watch(preferVoiceCaptureProvider),
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
          CategoryChipSelector(
            value: _category,
            enabled: !_saving,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 16),
          Text('Priority', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final priority in TaskPriority.values) ...[
                if (priority != TaskPriority.values.first)
                  const SizedBox(width: 8),
                Expanded(
                  child: _PriorityPill(
                    label: _label(priority.name),
                    selected: _priority == priority,
                    enabled: !_saving,
                    onTap: () => setState(() => _priority = priority),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FormQuickActionTile(
                  active: _dueDate != null,
                  label: 'Due date',
                  tooltip: dueTooltip,
                  onTap: _saving ? null : _pickDueDate,
                  onLongPress: _saving || _dueDate == null
                      ? null
                      : () => setState(() {
                            _dueDate = null;
                            _dueTimeMinutes = null;
                          }),
                  icon: SkyIcon(
                    SkyIcons.calendar,
                    color: _dueDate != null ? brand : muted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FormQuickActionTile(
                  active: _dueTimeMinutes != null,
                  label: 'Time',
                  tooltip: _dueTimeMinutes == null
                      ? 'Set time (Day Plan)'
                      : 'Change time · long-press to clear',
                  onTap: _saving ? null : _pickDueTime,
                  onLongPress: _saving || _dueTimeMinutes == null
                      ? null
                      : () => setState(() => _dueTimeMinutes = null),
                  icon: SkyIcon(
                    SkyIcons.pending,
                    color: _dueTimeMinutes != null ? brand : muted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FormQuickActionTile(
                  active: _pinned,
                  label: 'Pin',
                  tooltip: _pinned ? 'Unpin' : 'Pin',
                  onTap: _saving
                      ? null
                      : () => setState(() => _pinned = !_pinned),
                  icon: SkyIcon(
                    SkyIcons.pin,
                    color: _pinned ? brand : muted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FormQuickActionTile(
                  active: _isPrivate,
                  label: 'Hide',
                  tooltip: _isPrivate ? 'Make public' : 'Make private',
                  onTap: _saving
                      ? null
                      : () => setState(() => _isPrivate = !_isPrivate),
                  icon: SkyIcon(
                    SkyIcons.private,
                    color: _isPrivate ? brand : muted,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          if (_dueDate != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatDueLabel(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                  ),
            ),
          ],
          if (_dueTimeMinutes != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Duration', style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                DropdownButton<int>(
                  value: _durationMinutes,
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 45, child: Text('45 min')),
                    DropdownMenuItem(value: 60, child: Text('1 hour')),
                    DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                    DropdownMenuItem(value: 120, child: Text('2 hours')),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _durationMinutes = v);
                        },
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          VoiceMemoRecorder(
            controller: _voiceController,
            initialPath: widget.task?.voicePath,
            enabled: !_saving,
            titleBuilder: () => _titleController.text,
            onChanged: (path) => setState(() => _voicePath = path),
          ),
          const SizedBox(height: 20),
          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: FormActionButton(
                    label: 'Save',
                    busy: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FormActionButton(
                    label: widget.task!.completed ? 'Incomplete' : 'Complete',
                    variant: FormActionVariant.outlined,
                    onPressed: _saving ? null : _toggleComplete,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FormActionButton(
                    label: 'Archive',
                    variant: FormActionVariant.neutral,
                    onPressed: _saving ? null : _archive,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FormActionButton(
                    label: 'Delete',
                    variant: FormActionVariant.danger,
                    onPressed: _saving ? null : _delete,
                  ),
                ),
              ],
            ),
          ] else
            FormActionButton(
              label: 'Create task',
              busy: _saving,
              onPressed: _saving ? null : _save,
            ),
        ],
      ),
    );
  }

  String _label(String raw) => raw[0].toUpperCase() + raw.substring(1);
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.warning;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? accent.withValues(alpha: 0.18) : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected
              ? accent
              : scheme.onSurface.withValues(alpha: 0.18),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
                color: selected
                    ? const Color(0xFF9A6700)
                    : scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
