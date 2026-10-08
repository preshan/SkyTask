import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../core/utils/date_filters.dart';
import '../../../../shared/create/create_kind.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/async_error_view.dart';
import '../../../../shared/widgets/category_filter_bar.dart';
import '../../../../shared/widgets/category_label.dart';
import '../../../../shared/widgets/content_list_card.dart';
import '../../../../shared/widgets/list_add_button.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../../shared/widgets/voice_play_button.dart';
import '../../domain/entities/idea.dart';
import '../../../notes/domain/entities/note.dart';
import '../../../quick_links/domain/entities/quick_link.dart';
import '../../../quick_links/presentation/widgets/quick_link_form_sheet.dart';
import '../widgets/idea_form_sheet.dart';
import '../../../notes/presentation/widgets/note_form_sheet.dart';

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({
    super.key,
    this.initialTab = 0,
    this.createdToday = false,
    this.privateOnly = false,
  });

  final int initialTab;
  final bool createdToday;
  final bool privateOnly;

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late bool _createdToday;
  late bool _privateOnly;

  @override
  void initState() {
    super.initState();
    _createdToday = widget.createdToday;
    _privateOnly = widget.privateOnly;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant IdeasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.createdToday != widget.createdToday) {
      _createdToday = widget.createdToday;
    }
    if (oldWidget.privateOnly != widget.privateOnly) {
      _privateOnly = widget.privateOnly;
    }
    if (oldWidget.initialTab != widget.initialTab &&
        widget.initialTab >= 0 &&
        widget.initialTab < 3) {
      _tabController.index = widget.initialTab;
    }
  }

  CreateKind get _addKind => switch (_tabController.index) {
        0 => CreateKind.idea,
        1 => CreateKind.note,
        _ => CreateKind.link,
      };

  String get _addTooltip => switch (_tabController.index) {
        0 => 'Add idea',
        1 => 'Add note',
        _ => 'Add link',
      };

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ideas & Notes'),
        actions: [
          if (_createdToday || _privateOnly)
            IconButton(
              tooltip: 'Clear filters',
              onPressed: () => setState(() {
                _createdToday = false;
                _privateOnly = false;
              }),
              icon: const SkyIcon(SkyIcons.filterOff),
            )
          else
            IconButton(
              tooltip: 'Created today',
              onPressed: () => setState(() => _createdToday = true),
              icon: const SkyIcon(SkyIcons.today),
            ),
          ListAddButton(
            tooltip: _addTooltip,
            onPressed: () => openCreateSheet(context, ref, _addKind),
          ),
          ...skyTaskAppBarActions(context),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ideas'),
            Tab(text: 'Notes'),
            Tab(text: 'Links'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_createdToday)
            Material(
              color: AppColors.brandSecondary(context).withValues(alpha: 0.15),
              child: ListTile(
                dense: true,
                leading: SkyIcon(
                  SkyIcons.today,
                  color: AppColors.brandSecondary(context),
                ),
                title: const Text('Showing items created today'),
                trailing: TextButton(
                  onPressed: () => setState(() => _createdToday = false),
                  child: const Text('Clear'),
                ),
              ),
            ),
          if (_privateOnly)
            Material(
              color: AppColors.brand(context).withValues(alpha: 0.08),
              child: ListTile(
                dense: true,
                leading: SkyIcon(
                  SkyIcons.private,
                  color: AppColors.brand(context),
                ),
                title: const Text('Showing private items'),
                trailing: TextButton(
                  onPressed: () => setState(() => _privateOnly = false),
                  child: const Text('Clear'),
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _IdeasTab(
                  createdToday: _createdToday,
                  privateOnly: _privateOnly,
                ),
                _NotesTab(
                  createdToday: _createdToday,
                  privateOnly: _privateOnly,
                ),
                _LinksTab(
                  createdToday: _createdToday,
                  privateOnly: _privateOnly,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdeasTab extends ConsumerStatefulWidget {
  const _IdeasTab({
    required this.createdToday,
    required this.privateOnly,
  });

  final bool createdToday;
  final bool privateOnly;

  @override
  ConsumerState<_IdeasTab> createState() => _IdeasTabState();
}

class _IdeasTabState extends ConsumerState<_IdeasTab> {
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final ideasAsync = ref.watch(_ideasProvider);

    return ideasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncErrorView(
        error: e,
        onRetry: () => ref.invalidate(_ideasProvider),
      ),
      data: (ideas) {
        var filtered = ideas;
        if (widget.createdToday) {
          filtered = filtered
              .where((i) => DateFilters.isCreatedToday(i.createdAt))
              .toList();
        }
        if (widget.privateOnly) {
          filtered = filtered.where((i) => i.isPrivate).toList();
        }
        if (_categoryFilter != null) {
          final filter = _categoryFilter!.toLowerCase();
          filtered = filtered
              .where((i) => i.category.toLowerCase() == filter)
              .toList();
        }

        return Column(
          children: [
            CategoryFilterBar(
              selected: _categoryFilter,
              usedLabels: ideas.map((i) => i.category),
              onChanged: (v) => setState(() => _categoryFilter = v),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.privateOnly
                            ? 'No private ideas yet.'
                            : widget.createdToday
                                ? 'No ideas created today.'
                                : _categoryFilter != null
                                    ? 'No ideas in this category.'
                                    : 'Capture ideas instantly.\nTap + to start.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final idea = filtered[i];
                        return _IdeaCard(
                          idea: idea,
                          onTap: () =>
                              showIdeaFormSheet(context, ref, idea: idea),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _NotesTab extends ConsumerStatefulWidget {
  const _NotesTab({
    required this.createdToday,
    required this.privateOnly,
  });

  final bool createdToday;
  final bool privateOnly;

  @override
  ConsumerState<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<_NotesTab> {
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(_notesProvider);

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncErrorView(
        error: e,
        onRetry: () => ref.invalidate(_notesProvider),
      ),
      data: (notes) {
        var filtered = notes;
        if (widget.createdToday) {
          filtered = filtered
              .where((n) => DateFilters.isCreatedToday(n.createdAt))
              .toList();
        }
        if (widget.privateOnly) {
          filtered = filtered.where((n) => n.isPrivate).toList();
        }
        if (_categoryFilter != null) {
          final filter = _categoryFilter!.toLowerCase();
          filtered = filtered
              .where((n) => n.category.toLowerCase() == filter)
              .toList();
        }

        return Column(
          children: [
            CategoryFilterBar(
              selected: _categoryFilter,
              usedLabels: notes.map((n) => n.category),
              onChanged: (v) => setState(() => _categoryFilter = v),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.privateOnly
                            ? 'No private notes yet.'
                            : widget.createdToday
                                ? 'No notes created today.'
                                : _categoryFilter != null
                                    ? 'No notes in this category.'
                                    : 'Write long-form notes.\nTap + to start.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final note = filtered[i];
                        return _NoteCard(
                          note: note,
                          onTap: () =>
                              showNoteFormSheet(context, ref, note: note),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

final _ideasProvider = FutureProvider<List<Idea>>((ref) async {
  ref.watch(ideasRevisionProvider);
  final repo = await ref.read(ideaRepositoryProvider.future);
  return repo.getAll();
});

final _notesProvider = FutureProvider<List<Note>>((ref) async {
  ref.watch(notesRevisionProvider);
  final repo = await ref.read(noteRepositoryProvider.future);
  return repo.getAll();
});

final _quickLinksProvider = FutureProvider<List<QuickLink>>((ref) async {
  ref.watch(quickLinksRevisionProvider);
  final repo = await ref.read(quickLinkRepositoryProvider.future);
  return repo.getAll();
});

class _LinksTab extends ConsumerStatefulWidget {
  const _LinksTab({
    required this.createdToday,
    required this.privateOnly,
  });

  final bool createdToday;
  final bool privateOnly;

  @override
  ConsumerState<_LinksTab> createState() => _LinksTabState();
}

class _LinksTabState extends ConsumerState<_LinksTab> {
  String? _categoryFilter;

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(_quickLinksProvider);

    return linksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncErrorView(
        error: e,
        onRetry: () => ref.invalidate(_quickLinksProvider),
      ),
      data: (links) {
        var filtered = links;
        if (widget.createdToday) {
          filtered = filtered
              .where((l) => DateFilters.isCreatedToday(l.createdAt))
              .toList();
        }
        if (widget.privateOnly) {
          filtered = filtered.where((l) => l.isPrivate).toList();
        }
        if (_categoryFilter != null) {
          final filter = _categoryFilter!.toLowerCase();
          filtered = filtered
              .where((l) => l.category.toLowerCase() == filter)
              .toList();
        }

        return Column(
          children: [
            CategoryFilterBar(
              selected: _categoryFilter,
              usedLabels: links.map((l) => l.category),
              onChanged: (v) => setState(() => _categoryFilter = v),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.privateOnly
                            ? 'No private links yet.'
                            : widget.createdToday
                                ? 'No links created today.'
                                : _categoryFilter != null
                                    ? 'No links in this category.'
                                    : 'Save useful links with a title.\nShare from other apps or tap +.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final link = filtered[i];
                        return _LinkCard(
                          link: link,
                          onOpen: () => _openUrl(link.url),
                          onEdit: () => showQuickLinkFormSheet(
                            context,
                            ref,
                            link: link,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.link,
    required this.onOpen,
    required this.onEdit,
  });

  final QuickLink link;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ContentListCard(
      title: link.title,
      isPrivate: link.isPrivate,
      onTap: onOpen,
      onLongPress: onEdit,
      categorySlot: CategoryLabel(link.category),
      body: link.url,
    );
  }
}

class _IdeaCard extends StatelessWidget {
  const _IdeaCard({required this.idea, required this.onTap});

  final Idea idea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final body = idea.isVoice && idea.content.isEmpty
        ? 'Voice memo'
        : idea.content;
    final subtitleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        );

    return ContentListCard(
      title: displayItemTitle(
        title: idea.title,
        isVoice: idea.isVoice,
        createdAt: idea.createdAt,
      ),
      isPrivate: idea.isPrivate,
      onTap: onTap,
      categorySlot: Row(
        children: [
          CategoryLabel(idea.category),
          if (idea.tags.isNotEmpty) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                idea.tags.take(2).join(', '),
                style: subtitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      body: body.isEmpty ? null : body,
      trailing: [
        if (idea.isVoice && idea.voicePath != null)
          VoicePlayButton(path: idea.voicePath!, title: idea.title),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final body = note.isVoice && note.content.isEmpty
        ? 'Voice memo'
        : note.content;

    return ContentListCard(
      title: displayItemTitle(
        title: note.title,
        isVoice: note.isVoice,
        createdAt: note.createdAt,
      ),
      isPrivate: note.isPrivate,
      onTap: onTap,
      categorySlot: CategoryLabel(note.category),
      body: body.isEmpty ? null : body,
      trailing: [
        if (note.isVoice && note.voicePath != null)
          VoicePlayButton(path: note.voicePath!, title: note.title),
      ],
    );
  }
}
