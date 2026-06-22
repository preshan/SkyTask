import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
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
  late bool _isPrivate;
  bool _saving = false;

  bool get _isEditing => widget.idea != null;

  @override
  void initState() {
    super.initState();
    final idea = widget.idea;
    _titleController = TextEditingController(text: idea?.title ?? '');
    _contentController = TextEditingController(text: idea?.content ?? '');
    _tagsController = TextEditingController(text: idea?.tags.join(', ') ?? '');
    _isPrivate = idea?.isPrivate ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
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
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final repo = await ref.read(ideaRepositoryProvider.future);

    try {
      final idea = _isEditing
          ? widget.idea!.copyWith(
              title: title,
              content: _contentController.text.trim(),
              tags: _parseTags(),
              isPrivate: _isPrivate,
              updatedAt: now,
            )
          : Idea(
              id: const Uuid().v4(),
              title: title,
              content: _contentController.text.trim(),
              tags: _parseTags(),
              isPrivate: _isPrivate,
              createdAt: now,
              updatedAt: now,
            );

      await repo.save(idea);
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
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Private idea'),
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
