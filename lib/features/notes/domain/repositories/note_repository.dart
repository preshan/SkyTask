import '../entities/note.dart';

abstract class NoteRepository {
  Future<List<Note>> getAll();
  Future<Note?> getById(String id);
  Future<void> save(Note note);
  Future<void> delete(String id);
}
