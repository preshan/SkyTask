import 'package:isar/isar.dart';

import '../../../../core/database/isar_collections.dart';
import '../../domain/entities/quick_link.dart';
import '../../domain/repositories/quick_link_repository.dart';
import '../mappers/quick_link_mapper.dart';

class QuickLinkRepositoryImpl implements QuickLinkRepository {
  QuickLinkRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Future<List<QuickLink>> getAll() async {
    final results = await _isar.quickLinkCollections
        .where()
        .sortByUpdatedAtDesc()
        .findAll();
    return results.map(QuickLinkMapper.fromCollection).toList();
  }

  @override
  Future<QuickLink?> getById(String id) async {
    final result =
        await _isar.quickLinkCollections.filter().uuidEqualTo(id).findFirst();
    return result != null ? QuickLinkMapper.fromCollection(result) : null;
  }

  @override
  Future<void> save(QuickLink link) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.quickLinkCollections
          .filter()
          .uuidEqualTo(link.id)
          .findFirst();
      final collection = QuickLinkMapper.toCollection(link);
      if (existing != null) collection.id = existing.id;
      await _isar.quickLinkCollections.put(collection);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.quickLinkCollections
          .filter()
          .uuidEqualTo(id)
          .findFirst();
      if (existing != null) {
        await _isar.quickLinkCollections.delete(existing.id);
      }
    });
  }
}
