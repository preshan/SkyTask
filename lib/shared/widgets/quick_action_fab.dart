import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ideas/presentation/widgets/idea_form_sheet.dart';
import '../../features/notes/presentation/widgets/note_form_sheet.dart';
import '../../features/reminders/presentation/widgets/reminder_form_sheet.dart';
import '../../features/tasks/presentation/widgets/task_form_sheet.dart';

/// Expanding FAB with quick-create actions.
class QuickActionFab extends ConsumerStatefulWidget {
  const QuickActionFab({super.key});

  @override
  ConsumerState<QuickActionFab> createState() => _QuickActionFabState();
}

class _QuickActionFabState extends ConsumerState<QuickActionFab>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_expanded) ...[
          _ActionChip(
            icon: Icons.task_alt,
            label: 'New Task',
            onTap: () async {
              _toggle();
              await showTaskFormSheet(context, ref);
            },
          ),
          const SizedBox(height: 8),
          _ActionChip(
            icon: Icons.alarm,
            label: 'New Reminder',
            onTap: () async {
              _toggle();
              await showReminderFormSheet(context, ref);
            },
          ),
          const SizedBox(height: 8),
          _ActionChip(
            icon: Icons.lightbulb_outline,
            label: 'New Idea',
            onTap: () async {
              _toggle();
              await showIdeaFormSheet(context, ref);
            },
          ),
          const SizedBox(height: 8),
          _ActionChip(
            icon: Icons.note_add,
            label: 'New Note',
            onTap: () async {
              _toggle();
              await showNoteFormSheet(context, ref);
            },
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_expanded ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
