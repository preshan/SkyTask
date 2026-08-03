import '../../../../core/constants/task_categories.dart';
import '../../../../core/database/isar_collections.dart' as isar;
import '../../../../core/services/private_crypto_service.dart';
import '../../domain/entities/task.dart';

class TaskMapper {
  static final _crypto = PrivateCryptoService.instance;

  static Task fromCollection(isar.TaskCollection c) {
    final label = c.categoryLabel.trim().isNotEmpty
        ? TaskCategories.normalize(c.categoryLabel)
        : _labelFromLegacy(c.category);

    return Task(
      id: c.uuid,
      title: _crypto.reveal(c.title) ?? c.title,
      description: _crypto.reveal(c.description),
      priority: TaskPriority.values[c.priority.index],
      tags: _crypto.revealList(List.from(c.tags)),
      category: label,
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
    final label = TaskCategories.normalize(task.category);
    return isar.TaskCollection()
      ..uuid = task.id
      ..title = _crypto.protect(task.title, isPrivate: private) ?? task.title
      ..description = _crypto.protect(task.description, isPrivate: private)
      ..priority = isar.TaskPriority.values[task.priority.index]
      ..category = _legacyFromLabel(label)
      ..categoryLabel = label
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

  static String _labelFromLegacy(isar.TaskCategory category) {
    return switch (category) {
      isar.TaskCategory.work => TaskCategories.work,
      isar.TaskCategory.personal => TaskCategories.personal,
      isar.TaskCategory.health => 'Health',
      isar.TaskCategory.finance => 'Finance',
      isar.TaskCategory.study => 'Study',
      isar.TaskCategory.shopping => 'Shopping',
      isar.TaskCategory.custom => TaskCategories.personal,
    };
  }

  static isar.TaskCategory _legacyFromLabel(String label) {
    return switch (label.toLowerCase()) {
      'work' => isar.TaskCategory.work,
      'personal' => isar.TaskCategory.personal,
      'health' => isar.TaskCategory.health,
      'finance' => isar.TaskCategory.finance,
      'study' => isar.TaskCategory.study,
      'shopping' => isar.TaskCategory.shopping,
      _ => isar.TaskCategory.custom,
    };
  }
}
