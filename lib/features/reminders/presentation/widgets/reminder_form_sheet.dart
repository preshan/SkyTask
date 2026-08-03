import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../../core/constants/capture_preference.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../shared/widgets/private_icon_toggle.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../../shared/widgets/voice_memo_recorder.dart';
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
  late final FocusNode _descriptionFocus;
  late DateTime _dateTime;
  late NotificationOffset _offset;
  late bool _isPrivate;
  String? _voicePath;
  final _voiceController = VoiceMemoController();
  bool _saving = false;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.reminder;
    final initialTitle = (existing != null &&
            existing.isVoice &&
            VoiceMemoService.isPlaceholderTitle(existing.title))
        ? ''
        : (existing?.title ?? '');
    _titleController = TextEditingController(text: initialTitle);
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _descriptionFocus = FocusNode();
    _dateTime = existing?.reminderDateTime ??
        DateTime.now().add(const Duration(hours: 1));
    _offset = existing?.notificationOffset ?? NotificationOffset.atTime;
    _isPrivate = existing?.isPrivate ?? false;
    _voicePath = existing?.voicePath;

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
    setState(() => _saving = true);
    final now = DateTime.now();
    final voicePath = await _voiceController.finalize() ?? _voicePath;
    _voicePath = voicePath;
    final settings = ref.read(calendarSettingsProvider);
    final scheduler = await ref.read(reminderSchedulerProvider.future);
    final hasVoice = VoiceMemoService.hasVoice(voicePath);
    final title = voiceAwareTitle(
      rawTitle: _titleController.text,
      hasVoice: hasVoice,
      untitledFallback: 'Untitled reminder',
      at: _isEditing ? widget.reminder!.createdAt : now,
    );
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    try {
      final previousVoice =
          _isEditing ? widget.reminder!.voicePath : null;

      if (_isEditing) {
        final updated = widget.reminder!.copyWith(
          title: title,
          description: description,
          reminderDateTime: _dateTime,
          notificationOffset: _offset,
          isPrivate: _isPrivate,
          voicePath: voicePath,
          clearVoicePath: voicePath == null,
          updatedAt: now,
        );
        await scheduler.update(
          reminder: updated,
          syncCalendar:
              settings.canSyncToCalendar && !updated.isVoice && !updated.isPrivate,
          calendarId: settings.defaultCalendarId,
        );
      } else {
        await scheduler.schedule(
          reminder: Reminder(
            id: const Uuid().v4(),
            title: title,
            description: description,
            reminderDateTime: _dateTime,
            notificationOffset: _offset,
            isPrivate: _isPrivate,
            voicePath: voicePath,
            createdAt: now,
            updatedAt: now,
          ),
          addToCalendar:
              settings.canSyncToCalendar && !hasVoice && !_isPrivate,
          calendarId: settings.defaultCalendarId,
        );
      }

      if (previousVoice != null && previousVoice != voicePath) {
        await VoiceMemoService.deleteIfExists(previousVoice);
      }
      await ref.read(preferVoiceCaptureProvider.notifier).recordSave(
        hasVoice: hasVoice,
        hasTypedBody: description != null && description.isNotEmpty,
      );
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
            autofocus: !ref.watch(preferVoiceCaptureProvider),
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SkyIcon(SkyIcons.event),
            title: const Text('Date & time'),
            subtitle: Text('$dateLabel at $timeLabel'),
            trailing: const SkyIcon(SkyIcons.chevronRight),
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: PrivateIconToggle(
              value: _isPrivate,
              enabled: !_saving,
              onChanged: (v) => setState(() => _isPrivate = v),
            ),
          ),
          const SizedBox(height: 12),
          VoiceMemoRecorder(
            controller: _voiceController,
            initialPath: widget.reminder?.voicePath,
            enabled: !_saving,
            onChanged: (path) => setState(() => _voicePath = path),
          ),
          if (settings.canSyncToCalendar &&
              !VoiceMemoService.hasVoice(_voicePath) &&
              !_isPrivate)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const SkyIcon(SkyIcons.calendar),
              title: const Text('Sync to device calendar'),
              subtitle: Text(settings.defaultCalendarName ?? 'Calendar'),
              trailing: const SkyIcon(
                SkyIcons.checkCircle,
                color: Colors.green,
              ),
            ),
          if (VoiceMemoService.hasVoice(_voicePath) || _isPrivate)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _isPrivate
                    ? 'Private reminders are not added to calendar'
                    : 'Voice reminders are not added to calendar',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
