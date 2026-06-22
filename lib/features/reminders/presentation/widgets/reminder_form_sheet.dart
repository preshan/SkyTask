import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/reminder.dart';

Future<void> showReminderFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Reminder? reminder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _ReminderFormSheet(reminder: reminder),
    ),
  );
}

class _ReminderFormSheet extends ConsumerStatefulWidget {
  const _ReminderFormSheet({this.reminder});

  final Reminder? reminder;

  @override
  ConsumerState<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends ConsumerState<_ReminderFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _dateTime;
  late NotificationOffset _offset;
  late bool _isPrivate;
  bool _saving = false;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.reminder;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _dateTime = existing?.reminderDateTime ??
        DateTime.now().add(const Duration(hours: 1));
    _offset = existing?.notificationOffset ?? NotificationOffset.atTime;
    _isPrivate = existing?.isPrivate ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null || !mounted) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
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
    final settings = ref.read(calendarSettingsProvider);
    final scheduler = await ref.read(reminderSchedulerProvider.future);

    try {
      if (_isEditing) {
        final updated = widget.reminder!.copyWith(
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          reminderDateTime: _dateTime,
          notificationOffset: _offset,
          isPrivate: _isPrivate,
          updatedAt: now,
        );
        await scheduler.update(
          reminder: updated,
          syncCalendar: settings.canSyncToCalendar,
          calendarId: settings.defaultCalendarId,
        );
      } else {
        await scheduler.schedule(
          reminder: Reminder(
            id: const Uuid().v4(),
            title: title,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            reminderDateTime: _dateTime,
            notificationOffset: _offset,
            isPrivate: _isPrivate,
            createdAt: now,
            updatedAt: now,
          ),
          addToCalendar: settings.canSyncToCalendar,
          calendarId: settings.defaultCalendarId,
        );
      }

      refreshReminders(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save reminder: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final reminder = widget.reminder;
    if (reminder == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: const Text('This will cancel notifications and calendar events.'),
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
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final settings = ref.read(calendarSettingsProvider);
    final scheduler = await ref.read(reminderSchedulerProvider.future);
    await scheduler.cancel(
      reminder,
      calendarId: settings.defaultCalendarId,
    );
    refreshReminders(ref);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleComplete() async {
    final reminder = widget.reminder;
    if (reminder == null) return;

    setState(() => _saving = true);
    final settings = ref.read(calendarSettingsProvider);
    final scheduler = await ref.read(reminderSchedulerProvider.future);
    await scheduler.update(
      reminder: reminder.copyWith(
        isCompleted: !reminder.isCompleted,
        updatedAt: DateTime.now(),
      ),
      syncCalendar: settings.canSyncToCalendar,
      calendarId: settings.defaultCalendarId,
    );
    refreshReminders(ref);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(calendarSettingsProvider);
    final dateLabel =
        MaterialLocalizations.of(context).formatFullDate(_dateTime);
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(_dateTime),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isEditing ? 'Edit Reminder' : 'New Reminder',
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
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('Date & time'),
            subtitle: Text('$dateLabel at $timeLabel'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _saving ? null : _pickDate,
          ),
          DropdownButtonFormField<NotificationOffset>(
            value: _offset,
            decoration: const InputDecoration(
              labelText: 'Notify me',
              border: OutlineInputBorder(),
            ),
            items: NotificationOffset.values
                .where((o) => o != NotificationOffset.custom)
                .map(
                  (o) => DropdownMenuItem(
                    value: o,
                    child: Text(notificationOffsetLabel(o)),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (v) => setState(() => _offset = v ?? _offset),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Private reminder'),
            subtitle: const Text('Hide content behind app lock'),
            value: _isPrivate,
            onChanged: _saving ? null : (v) => setState(() => _isPrivate = v),
          ),
          if (settings.canSyncToCalendar)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Sync to device calendar'),
              subtitle: Text(settings.defaultCalendarName ?? 'Calendar'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
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
                : Text(_isEditing ? 'Save changes' : 'Create reminder'),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : _toggleComplete,
              child: Text(
                widget.reminder!.isCompleted
                    ? 'Mark as active'
                    : 'Mark as completed',
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _delete,
              child: const Text('Delete reminder'),
            ),
          ],
        ],
      ),
    );
  }
}
