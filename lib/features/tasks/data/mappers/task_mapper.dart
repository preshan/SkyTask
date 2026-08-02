import '../../../../core/database/isar_collections.dart' as isar;
import '../../../../core/services/private_crypto_service.dart';
import '../../domain/entities/task.dart';

class TaskMapper {
  static final _crypto = PrivateCryptoService.instance;

  static Task fromCollection(isar.TaskCollection c) {
    return Task(
      id: c.uuid,
      title: _crypto.reveal(c.title) ?? c.title,
      description: _crypto.reveal(c.description),
      priority: TaskPriority.values[c.priority.index],
      tags: _crypto.revealList(List.from(c.tags)),
      category: TaskCategory.values[c.category.index],
      dueDate: c.dueDate,
      completed: c.completed,
      pinned: c.pinned,
      archived: c.archived,
      isPrivate: c.isPrivate,
      voicePath: c.voicePath,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  static isar.TaskCollection toCollection(Task task) {
    final private = task.isPrivate;
    return isar.TaskCollection()
      ..uuid = task.id
      ..title = _crypto.protect(task.title, isPrivate: private) ?? task.title
      ..description = _crypto.protect(task.description, isPrivate: private)
      ..priority = isar.TaskPriority.values[task.priority.index]
      ..category = isar.TaskCategory.values[task.category.index]
      ..tags = _crypto.protectList(task.tags, isPrivate: private)
      ..dueDate = task.dueDate
      ..completed = task.completed
      ..pinned = task.pinned
      ..archived = task.archived
      ..isPrivate = task.isPrivate
      ..voicePath = task.voicePath
      ..createdAt = task.createdAt
      ..updatedAt = task.updatedAt;
  }
}
