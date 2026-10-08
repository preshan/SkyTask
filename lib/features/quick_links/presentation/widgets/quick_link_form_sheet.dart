import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/task_categories.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/category_chip_selector.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../../shared/widgets/form_action_button.dart';
import '../../../../shared/widgets/form_quick_action_tile.dart';
import '../../../../shared/widgets/form_sheet_header.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../domain/entities/quick_link.dart';
import '../../domain/shared_link_payload.dart';

Future<void> showQuickLinkFormSheet(
  BuildContext context,
  WidgetRef ref, {
  QuickLink? link,
  SharedLinkPayload? shared,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _QuickLinkFormSheet(link: link, shared: shared),
    ),
  );
}

class _QuickLinkFormSheet extends ConsumerStatefulWidget {
  const _QuickLinkFormSheet({this.link, this.shared});

  final QuickLink? link;
  final SharedLinkPayload? shared;

  @override
  ConsumerState<_QuickLinkFormSheet> createState() =>
      _QuickLinkFormSheetState();
}

class _QuickLinkFormSheetState extends ConsumerState<_QuickLinkFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _notesController;
  late final FocusNode _titleFocus;
  late final FocusNode _urlFocus;
  late String _category;
  late bool _isPrivate;
  bool _saving = false;
  String? _urlError;

  bool get _isEditing => widget.link != null;

  @override
  void initState() {
    super.initState();
    final link = widget.link;
    final shared = widget.shared;
    _titleController = TextEditingController(
      text: link?.title ?? shared?.titleHint ?? '',
    );
    _urlController = TextEditingController(
      text: link?.url ?? shared?.url ?? '',
    );
    _notesController = TextEditingController(text: link?.notes ?? '');
    _titleFocus = FocusNode();
    _urlFocus = FocusNode();
    _category = TaskCategories.normalize(
      link?.category ?? TaskCategories.personal,
    );
    _isPrivate = link?.isPrivate ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_urlController.text.trim().isEmpty) {
        _urlFocus.requestFocus();
      } else {
        _titleFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    _titleFocus.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  String? _normalizeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final withScheme = RegExp(r'^https?://', caseSensitive: false)
            .hasMatch(trimmed)
        ? trimmed
        : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri.toString();
  }

  Future<void> _save() async {
    final url = _normalizeUrl(_urlController.text);
    if (url == null) {
      setState(() => _urlError = 'Enter a valid http(s) link');
      return;
    }
    setState(() {
      _urlError = null;
      _saving = true;
    });

    final now = DateTime.now();
    final title = _titleController.text.trim().isEmpty
        ? url
        : _titleController.text.trim();
    final repo = await ref.read(quickLinkRepositoryProvider.future);

    try {
      final link = _isEditing
          ? widget.link!.copyWith(
              title: title,
              url: url,
              notes: _notesController.text.trim(),
              category: _category,
              isPrivate: _isPrivate,
              updatedAt: now,
            )
          : QuickLink(
              id: const Uuid().v4(),
              title: title,
              url: url,
              notes: _notesController.text.trim(),
              category: _category,
              isPrivate: _isPrivate,
              createdAt: now,
              updatedAt: now,
            );

      await repo.save(link);
      if (!TaskCategories.isDefault(link.category)) {
        await ref
            .read(customTaskCategoriesProvider.notifier)
            .add(link.category);
      }
      refreshQuickLinks(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save link: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final link = widget.link;
    if (link == null) return;

    final ok = await confirmDelete(context, title: 'Delete link?');
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    final repo = await ref.read(quickLinkRepositoryProvider.future);
    await repo.delete(link.id);
    refreshQuickLinks(ref);
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
          FormSheetHeader(_isEditing ? 'Edit Link' : 'New Link'),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            focusNode: _titleFocus,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _urlFocus.requestFocus(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            focusNode: _urlFocus,
            decoration: InputDecoration(
              labelText: 'Link',
              border: const OutlineInputBorder(),
              errorText: _urlError,
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CategoryChipSelector(
            value: _category,
            enabled: !_saving,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 20),
          FormActionButton(
            label: 'Save',
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
