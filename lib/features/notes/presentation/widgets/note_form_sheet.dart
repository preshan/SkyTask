import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/content_providers.dart';
import '../../../../core/constants/capture_preference.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../../shared/widgets/private_icon_toggle.dart';
import '../../../../shared/widgets/voice_memo_recorder.dart';
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
  late final FocusNode _contentFocus;
  late bool _isPrivate;
  String? _voicePath;
  final _voiceController = VoiceMemoController();
  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    final initialTitle = (note != null &&
            note.isVoice &&
            VoiceMemoService.isPlaceholderTitle(note.title))
        ? ''
        : (note?.title ?? '');
    _titleController = TextEditingController(text: initialTitle);
    _contentController = TextEditingController(text: note?.content ?? '');
    _contentFocus = FocusNode();
    _isPrivate = note?.isPrivate ?? false;
    _voicePath = note?.voicePath;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(preferVoiceCaptureProvider)) {
        _contentFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    final voicePath = await _voiceController.finalize() ?? _voicePath;
    _voicePath = voicePath;
    final repo = await ref.read(noteRepositoryProvider.future);
    final hasVoice = VoiceMemoService.hasVoice(voicePath);
    final title = voiceAwareTitle(
      rawTitle: _titleController.text,
      hasVoice: hasVoice,
      untitledFallback: 'Untitled note',
      at: _isEditing ? widget.note!.createdAt : now,
    );

    try {
      final previousVoice = _isEditing ? widget.note!.voicePath : null;

      final note = _isEditing
          ? widget.note!.copyWith(
              title: title,
              content: _contentController.text.trim(),
              isPrivate: _isPrivate,
              voicePath: voicePath,
              clearVoicePath: voicePath == null,
              updatedAt: now,
            )
          : Note(
              id: const Uuid().v4(),
              title: title,
              content: _contentController.text.trim(),
              isPrivate: _isPrivate,
              voicePath: voicePath,
              createdAt: now,
              updatedAt: now,
            );

      await repo.save(note);
      await ref.read(preferVoiceCaptureProvider.notifier).recordSave(
        hasVoice: hasVoice,
        hasTypedBody: _contentController.text.trim().isNotEmpty,
      );
      if (previousVoice != null && previousVoice != voicePath) {
        await VoiceMemoService.deleteIfExists(previousVoice);
      }
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
              labelText: 'Title (optional)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _contentFocus.requestFocus(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            focusNode: _contentFocus,
            autofocus: !ref.watch(preferVoiceCaptureProvider),
            decoration: const InputDecoration(
              labelText: 'Note body',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
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
            initialPath: widget.note?.voicePath,
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
