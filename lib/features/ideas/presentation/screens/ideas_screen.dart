import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../core/utils/date_filters.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/private_content_gate.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../../shared/widgets/voice_play_button.dart';
import '../../domain/entities/idea.dart';
import '../../../notes/domain/entities/note.dart';
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
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
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
        widget.initialTab < 2) {
      _tabController.index = widget.initialTab;
    }
  }

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
          ...skyTaskAppBarActions(context),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Ideas',
              icon: SkyIcon(SkyIcons.lightbulb, size: 20),
            ),
            Tab(
              text: 'Notes',
              icon: SkyIcon(SkyIcons.notes, size: 20),
            ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdeasTab extends ConsumerWidget {
  const _IdeasTab({
    required this.createdToday,
    required this.privateOnly,
  });

  final bool createdToday;
  final bool privateOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasAsync = ref.watch(_ideasProvider);

    return ideasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (ideas) {
        var filtered = ideas;
        if (createdToday) {
          filtered = filtered
              .where((i) => DateFilters.isCreatedToday(i.createdAt))
              .toList();
        }
        if (privateOnly) {
          filtered = filtered.where((i) => i.isPrivate).toList();
        }
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              privateOnly
                  ? 'No private ideas yet.'
                  : createdToday
                      ? 'No ideas created today.'
                      : 'Capture ideas instantly.\nTap + to start.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final idea = filtered[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _IdeaCard(
                idea: idea,
                onTap: () => showIdeaFormSheet(context, ref, idea: idea),
              ),
            );
          },
        );
      },
    );
  }
}

class _NotesTab extends ConsumerWidget {
  const _NotesTab({
    required this.createdToday,
    required this.privateOnly,
  });

  final bool createdToday;
  final bool privateOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(_notesProvider);

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (notes) {
        var filtered = notes;
        if (createdToday) {
          filtered = filtered
              .where((n) => DateFilters.isCreatedToday(n.createdAt))
              .toList();
        }
        if (privateOnly) {
          filtered = filtered.where((n) => n.isPrivate).toList();
        }
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              privateOnly
                  ? 'No private notes yet.'
                  : createdToday
                      ? 'No notes created today.'
                      : 'Write long-form notes.\nTap + to start.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final note = filtered[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NoteCard(
                note: note,
                onTap: () => showNoteFormSheet(context, ref, note: note),
              ),
            );
          },
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

class _IdeaCard extends StatelessWidget {
  const _IdeaCard({required this.idea, required this.onTap});

  final Idea idea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: PrivateContentGate(
        isPrivate: idea.isPrivate,
        child: ListTile(
          onTap: onTap,
          leading: SkyIcon(
            idea.isVoice ? SkyIcons.mic : SkyIcons.lightbulb,
            color: AppColors.brandSecondary(context),
          ),
          title: Text(
            displayItemTitle(
              title: idea.title,
              isVoice: idea.isVoice,
              createdAt: idea.createdAt,
            ),
          ),
          subtitle: Text(
            idea.isVoice && idea.content.isEmpty
                ? 'Voice memo'
                : idea.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (idea.isVoice && idea.voicePath != null)
                VoicePlayButton(path: idea.voicePath!),
              if (idea.tags.isEmpty)
                const SkyIcon(SkyIcons.chevronRight)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      idea.tags.take(2).join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SkyIcon(SkyIcons.chevronRight, size: 18),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: PrivateContentGate(
        isPrivate: note.isPrivate,
        child: ListTile(
          onTap: onTap,
          leading: SkyIcon(
            note.isVoice ? SkyIcons.mic : SkyIcons.notes,
            color: AppColors.brandSecondary(context),
          ),
          title: Text(
            displayItemTitle(
              title: note.title,
              isVoice: note.isVoice,
              createdAt: note.createdAt,
            ),
          ),
          subtitle: Text(
            note.isVoice && note.content.isEmpty
                ? 'Voice memo'
                : note.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (note.isVoice && note.voicePath != null)
                VoicePlayButton(path: note.voicePath!),
              const SkyIcon(SkyIcons.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}
