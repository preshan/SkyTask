import 'package:isar/isar.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../mappers/note_mapper.dart';
import '../../../../core/database/isar_collections.dart';
import '../../../../core/services/voice_memo_service.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Future<List<Note>> getAll() async {
    final results =
        await _isar.noteCollections.where().sortByUpdatedAtDesc().findAll();
    return results.map(NoteMapper.fromCollection).toList();
  }

  @override
  Future<Note?> getById(String id) async {
    final result =
        await _isar.noteCollections.filter().uuidEqualTo(id).findFirst();
    return result != null ? NoteMapper.fromCollection(result) : null;
  }

  @override
  Future<void> save(Note note) async {
    await _isar.writeTxn(() async {
      final existing =
          await _isar.noteCollections.filter().uuidEqualTo(note.id).findFirst();
      final collection = NoteMapper.toCollection(note);
      if (existing != null) collection.id = existing.id;
      await _isar.noteCollections.put(collection);
    });
  }

  @override
  Future<void> delete(String id) async {
    String? voicePath;
    await _isar.writeTxn(() async {
      final existing =
          await _isar.noteCollections.filter().uuidEqualTo(id).findFirst();
      if (existing != null) {
        voicePath = existing.voicePath;
        await _isar.noteCollections.delete(existing.id);
      }
    });
    await VoiceMemoService.deleteIfExists(voicePath);
  }
}
