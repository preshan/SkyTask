import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/content_providers.dart';
import '../../../../core/constants/capture_preference.dart';
import '../../../../core/constants/task_categories.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/category_chip_selector.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../../shared/widgets/form_action_button.dart';
import '../../../../shared/widgets/form_quick_action_tile.dart';
import '../../../../shared/widgets/form_sheet_header.dart';
import '../../../../shared/widgets/sky_icon.dart';
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
    showDragHandle: true,
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
  late String _category;
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
    _category = TaskCategories.normalize(
      idea?.category ?? TaskCategories.personal,
    );
    _isPrivate = idea?.isPrivate ?? false;
    _voicePath = idea?.voicePath;

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
              category: _category,
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
              category: _category,
              tags: _parseTags(),
              isPrivate: _isPrivate,
              voicePath: voicePath,
              createdAt: now,
              updatedAt: now,
            );

      await repo.save(idea);
      if (!TaskCategories.isDefault(idea.category)) {
        await ref
            .read(customTaskCategoriesProvider.notifier)
            .add(idea.category);
      }
      await ref.read(preferVoiceCaptureProvider.notifier).recordSave(
        hasVoice: hasVoice,
        hasTypedBody: _contentController.text.trim().isNotEmpty,
      );
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
    final brand = AppColors.brand(context);
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FormSheetHeader(_isEditing ? 'Edit Idea' : 'New Idea'),
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
            onSubmitted: (_) => _contentFocus.requestFocus(),
          ),
          const SizedBox(height: 8),
          CategoryChipSelector(
            value: _category,
            enabled: !_saving,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            focusNode: _contentFocus,
            autofocus: !ref.watch(preferVoiceCaptureProvider),
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Details',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (comma separated)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 88,
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
          ),
          const SizedBox(height: 12),
          VoiceMemoRecorder(
            controller: _voiceController,
            initialPath: widget.idea?.voicePath,
            enabled: !_saving,
            titleBuilder: () => _titleController.text,
            onChanged: (path) => setState(() => _voicePath = path),
          ),
          const SizedBox(height: 20),
          FormActionButton(
            label: _isEditing ? 'Save' : 'Create idea',
            busy: _saving,
            onPressed: _saving ? null : _save,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 10),
            FormActionButton(
              label: 'Delete',
              variant: FormActionVariant.danger,
              onPressed: _saving ? null : _delete,
            ),
          ],
        ],
      ),
    );
  }
}
