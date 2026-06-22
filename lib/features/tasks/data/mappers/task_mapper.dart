import 'package:isar/isar.dart';

import '../../../../core/database/isar_collections.dart' as isar;
import '../../domain/entities/task.dart';

class TaskMapper {
  static Task fromCollection(isar.TaskCollection c) {
    return Task(
      id: c.uuid,
      title: c.title,
      description: c.description,
      priority: TaskPriority.values[c.priority.index],
      tags: List.from(c.tags),
      category: TaskCategory.values[c.category.index],
      dueDate: c.dueDate,
      completed: c.completed,
      pinned: c.pinned,
      archived: c.archived,
      isPrivate: c.isPrivate,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  static isar.TaskCollection toCollection(Task task) {
    return isar.TaskCollection()
      ..uuid = task.id
      ..title = task.title
      ..description = task.description
      ..priority = isar.TaskPriority.values[task.priority.index]
      ..category = isar.TaskCategory.values[task.category.index]
      ..tags = List.from(task.tags)
      ..dueDate = task.dueDate
      ..completed = task.completed
      ..pinned = task.pinned
      ..archived = task.archived
      ..isPrivate = task.isPrivate
      ..createdAt = task.createdAt
      ..updatedAt = task.updatedAt;
  }
}
