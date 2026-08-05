import '../../../../core/constants/task_categories.dart';
import '../../../../core/database/isar_collections.dart' as isar;
import '../../../../core/services/private_crypto_service.dart';
import '../../domain/entities/idea.dart';

class IdeaMapper {
  static final _crypto = PrivateCryptoService.instance;

  static Idea fromCollection(isar.IdeaCollection c) {
    final label = c.categoryLabel.trim().isNotEmpty
        ? TaskCategories.normalize(c.categoryLabel)
        : TaskCategories.personal;
    return Idea(
      id: c.uuid,
      title: _crypto.reveal(c.title) ?? c.title,
      content: _crypto.reveal(c.content) ?? c.content,
      category: label,
      tags: _crypto.revealList(List.from(c.tags)),
      isPrivate: c.isPrivate,
      voicePath: c.voicePath,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  static isar.IdeaCollection toCollection(Idea idea) {
    final private = idea.isPrivate;
    return isar.IdeaCollection()
      ..uuid = idea.id
      ..title = _crypto.protect(idea.title, isPrivate: private) ?? idea.title
      ..content =
          _crypto.protect(idea.content, isPrivate: private) ?? idea.content
      ..categoryLabel = TaskCategories.normalize(idea.category)
      ..tags = _crypto.protectList(idea.tags, isPrivate: private)
      ..isPrivate = idea.isPrivate
      ..voicePath = idea.voicePath
      ..createdAt = idea.createdAt
      ..updatedAt = idea.updatedAt;
  }
}
