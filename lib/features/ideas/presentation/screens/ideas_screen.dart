import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/content_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared/widgets/private_content_gate.dart';
import '../../domain/entities/idea.dart';
import '../../../notes/domain/entities/note.dart';
import '../widgets/idea_form_sheet.dart';
import '../../../notes/presentation/widgets/note_form_sheet.dart';

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _create() {
    if (_tabController.index == 0) {
      showIdeaFormSheet(context, ref);
    } else {
      showNoteFormSheet(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ideas & Notes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ideas', icon: Icon(Icons.lightbulb_outline)),
            Tab(text: 'Notes', icon: Icon(Icons.note_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _IdeasTab(),
          _NotesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: Icon(_tabController.index == 0 ? Icons.lightbulb : Icons.note_add),
      ),
    );
  }
}

class _IdeasTab extends ConsumerWidget {
  const _IdeasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasAsync = ref.watch(_ideasProvider);

    return ideasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (ideas) {
        if (ideas.isEmpty) {
          return const Center(
            child: Text('Capture ideas instantly.\nTap + to start.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ideas.length,
          itemBuilder: (_, i) {
            final idea = ideas[i];
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
  const _NotesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(_notesProvider);

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (notes) {
        if (notes.isEmpty) {
          return const Center(
            child: Text('Write long-form notes.\nTap + to start.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (_, i) {
            final note = notes[i];
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
        title: idea.title,
        child: ListTile(
          onTap: onTap,
          leading: const Icon(Icons.lightbulb_outline),
          title: Text(idea.isPrivate ? 'Private Item' : idea.title),
          subtitle: Text(
            idea.isPrivate ? '🔒 Hidden Content' : idea.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: idea.tags.isEmpty
              ? const Icon(Icons.chevron_right)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      idea.tags.take(2).join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Icon(Icons.chevron_right, size: 18),
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
        title: note.title,
        child: ListTile(
          onTap: onTap,
          leading: const Icon(Icons.note_outlined),
          title: Text(note.isPrivate ? 'Private Item' : note.title),
          subtitle: Text(
            note.isPrivate ? '🔒 Hidden Content' : note.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
