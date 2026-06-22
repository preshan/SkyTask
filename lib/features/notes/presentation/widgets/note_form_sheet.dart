import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../domain/entities/note.dart';

Future<void> showNoteFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Note? note,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _NoteFormSheet(note: note),
    ),
  );
}

class _NoteFormSheet extends ConsumerStatefulWidget {
  const _NoteFormSheet({this.note});

  final Note? note;

  @override
  ConsumerState<_NoteFormSheet> createState() => _NoteFormSheetState();
}

class _NoteFormSheetState extends ConsumerState<_NoteFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late bool _isPrivate;
  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _isPrivate = note?.isPrivate ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
    final repo = await ref.read(noteRepositoryProvider.future);

    try {
      final note = _isEditing
          ? widget.note!.copyWith(
              title: title,
              content: _contentController.text.trim(),
              isPrivate: _isPrivate,
              updatedAt: now,
            )
          : Note(
              id: const Uuid().v4(),
              title: title,
              content: _contentController.text.trim(),
              isPrivate: _isPrivate,
              createdAt: now,
              updatedAt: now,
            );

      await repo.save(note);
      refreshNotes(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final note = widget.note;
    if (note == null) return;

    final ok = await confirmDelete(context, title: 'Delete note?');
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    final repo = await ref.read(noteRepositoryProvider.future);
    await repo.delete(note.id);
    refreshNotes(ref);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isEditing ? 'Edit Note' : 'New Note',
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
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Note body',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Private note'),
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
                : Text(_isEditing ? 'Save changes' : 'Create note'),
          ),
          if (_isEditing)
            TextButton(
              onPressed: _saving ? null : _delete,
              child: const Text('Delete note'),
            ),
        ],
      ),
    );
  }
}
