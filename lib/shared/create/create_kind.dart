import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ideas/presentation/widgets/idea_form_sheet.dart';
import '../../features/notes/presentation/widgets/note_form_sheet.dart';
import '../../features/reminders/presentation/widgets/reminder_form_sheet.dart';
import '../../features/tasks/presentation/widgets/task_form_sheet.dart';

/// What to open from the in-app Create menu or a launcher shortcut.
enum CreateKind { task, reminder, idea, note }

/// Pending create requested via device launcher shortcut (survives lock/splash).
final pendingCreateKindProvider = StateProvider<CreateKind?>((ref) => null);

CreateKind? createKindFromShortcutType(String type) {
  return switch (type) {
    'create_task' => CreateKind.task,
    'create_reminder' => CreateKind.reminder,
    'create_idea' => CreateKind.idea,
    'create_note' => CreateKind.note,
    _ => null,
  };
}

CreateKind? createKindFromQuery(String? value) {
  return switch (value) {
    'task' => CreateKind.task,
    'reminder' => CreateKind.reminder,
    'idea' => CreateKind.idea,
    'note' => CreateKind.note,
    _ => null,
  };
}

Future<void> openCreateSheet(
  BuildContext context,
  WidgetRef ref,
  CreateKind kind,
) {
  return switch (kind) {
    CreateKind.task => showTaskFormSheet(context, ref),
    CreateKind.reminder => showReminderFormSheet(context, ref),
    CreateKind.idea => showIdeaFormSheet(context, ref),
    CreateKind.note => showNoteFormSheet(context, ref),
  };
}
