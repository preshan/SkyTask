import '../../../../core/constants/task_categories.dart';
import '../../../../core/database/isar_collections.dart' as isar;
import '../../../../core/services/private_crypto_service.dart';
import '../../domain/entities/quick_link.dart';

class QuickLinkMapper {
  static final _crypto = PrivateCryptoService.instance;

  static QuickLink fromCollection(isar.QuickLinkCollection c) {
    final label = c.categoryLabel.trim().isNotEmpty
        ? TaskCategories.normalize(c.categoryLabel)
        : TaskCategories.personal;
    return QuickLink(
      id: c.uuid,
      title: _crypto.reveal(c.title) ?? c.title,
      url: _crypto.reveal(c.url) ?? c.url,
      notes: _crypto.reveal(c.notes) ?? c.notes,
      category: label,
      isPrivate: c.isPrivate,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  static isar.QuickLinkCollection toCollection(QuickLink link) {
    final private = link.isPrivate;
    return isar.QuickLinkCollection()
      ..uuid = link.id
      ..title = _crypto.protect(link.title, isPrivate: private) ?? link.title
      ..url = _crypto.protect(link.url, isPrivate: private) ?? link.url
      ..notes = _crypto.protect(link.notes, isPrivate: private) ?? link.notes
      ..categoryLabel = TaskCategories.normalize(link.category)
      ..isPrivate = link.isPrivate
      ..createdAt = link.createdAt
      ..updatedAt = link.updatedAt;
  }
}
