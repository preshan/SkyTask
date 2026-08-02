import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../../shared/widgets/private_icon_toggle.dart';
import '../../../../shared/widgets/voice_memo_recorder.dart';
import '../../domain/entities/idea.dart';

Future<void> showIdeaFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Idea? idea,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _IdeaFormSheet(idea: idea),
    ),
  );
}

class _IdeaFormSheet extends ConsumerStatefulWidget {
  const _IdeaFormSheet({this.idea});

  final Idea? idea;

  @override
  ConsumerState<_IdeaFormSheet> createState() => _IdeaFormSheetState();
}

class _IdeaFormSheetState extends ConsumerState<_IdeaFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late final FocusNode _contentFocus;
  late bool _isPrivate;
  String? _voicePath;
  final _voiceController = VoiceMemoController();
  bool _saving = false;

  bool get _isEditing => widget.idea != null;

  @override
  void initState() {
    super.initState();
    final idea = widget.idea;
    final initialTitle = (idea != null &&
            idea.isVoice &&
            VoiceMemoService.isPlaceholderTitle(idea.title))
        ? ''
        : (idea?.title ?? '');
    _titleController = TextEditingController(text: initialTitle);
    _contentController = TextEditingController(text: idea?.content ?? '');
    _tagsController = TextEditingController(text: idea?.tags.join(', ') ?? '');
    _contentFocus = FocusNode();
    _isPrivate = idea?.isPrivate ?? false;
    _voicePath = idea?.voicePath;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _contentFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  List<String> _parseTags() {
    return _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    final voicePath = await _voiceController.finalize() ?? _voicePath;
    _voicePath = voicePath;
    final repo = await ref.read(ideaRepositoryProvider.future);
    final hasVoice = VoiceMemoService.hasVoice(voicePath);
    final title = voiceAwareTitle(
      rawTitle: _titleController.text,
      hasVoice: hasVoice,
      untitledFallback: 'Untitled idea',
      at: _isEditing ? widget.idea!.createdAt : now,
    );

    try {
      final previousVoice = _isEditing ? widget.idea!.voicePath : null;

      final idea = _isEditing
          ? widget.idea!.copyWith(
              title: title,
              content: _contentController.text.trim(),
              tags: _parseTags(),
              isPrivate: _isPrivate,
              voicePath: voicePath,
              clearVoicePath: voicePath == null,
              updatedAt: now,
            )
          : Idea(
              id: const Uuid().v4(),
              title: title,
              content: _contentController.text.trim(),
              tags: _parseTags(),
              isPrivate: _isPrivate,
              voicePath: voicePath,
              createdAt: now,
              updatedAt: now,
            );

      await repo.save(idea);
      if (previousVoice != null && previousVoice != voicePath) {
        await VoiceMemoService.deleteIfExists(previousVoice);
      }
      refreshIdeas(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save idea: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final idea = widget.idea;
    if (idea == null) return;

    final ok = await confirmDelete(context, title: 'Delete idea?');
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    final repo = await ref.read(ideaRepositoryProvider.future);
    await repo.delete(idea.id);
    refreshIdeas(ref);
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
            _isEditing ? 'Edit Idea' : 'New Idea',
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
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Details',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (comma separated)',
              border: OutlineInputBorder(),
            ),
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
            initialPath: widget.idea?.voicePath,
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
                : Text(_isEditing ? 'Save changes' : 'Create idea'),
          ),
          if (_isEditing)
            TextButton(
              onPressed: _saving ? null : _delete,
              child: const Text('Delete idea'),
            ),
        ],
      ),
    );
  }
}
