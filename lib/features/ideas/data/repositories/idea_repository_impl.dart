import 'package:isar/isar.dart';

import '../../domain/entities/idea.dart';
import '../../domain/repositories/idea_repository.dart';
import '../mappers/idea_mapper.dart';
import '../../../../core/database/isar_collections.dart';
import '../../../../core/services/voice_memo_service.dart';

class IdeaRepositoryImpl implements IdeaRepository {
  IdeaRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Future<List<Idea>> getAll() async {
    final results =
        await _isar.ideaCollections.where().sortByUpdatedAtDesc().findAll();
    return results.map(IdeaMapper.fromCollection).toList();
  }

  @override
  Future<Idea?> getById(String id) async {
    final result =
        await _isar.ideaCollections.filter().uuidEqualTo(id).findFirst();
    return result != null ? IdeaMapper.fromCollection(result) : null;
  }

  @override
  Future<void> save(Idea idea) async {
    await _isar.writeTxn(() async {
      final existing =
          await _isar.ideaCollections.filter().uuidEqualTo(idea.id).findFirst();
      final collection = IdeaMapper.toCollection(idea);
      if (existing != null) collection.id = existing.id;
      await _isar.ideaCollections.put(collection);
    });
  }

  @override
  Future<void> delete(String id) async {
    String? voicePath;
    await _isar.writeTxn(() async {
      final existing =
          await _isar.ideaCollections.filter().uuidEqualTo(id).findFirst();
      if (existing != null) {
        voicePath = existing.voicePath;
        await _isar.ideaCollections.delete(existing.id);
      }
    });
    await VoiceMemoService.deleteIfExists(voicePath);
  }
}
