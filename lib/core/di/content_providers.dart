import 'package:flutter_riverpod/flutter_riverpod.dart';

final tasksRevisionProvider = StateProvider<int>((ref) => 0);
final ideasRevisionProvider = StateProvider<int>((ref) => 0);
final notesRevisionProvider = StateProvider<int>((ref) => 0);

void refreshTasks(WidgetRef ref) {
  ref.read(tasksRevisionProvider.notifier).state++;
}

void refreshIdeas(WidgetRef ref) {
  ref.read(ideasRevisionProvider.notifier).state++;
}

void refreshNotes(WidgetRef ref) {
  ref.read(notesRevisionProvider.notifier).state++;
}
