import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../mappers/task_mapper.dart';
import '../../../../core/database/isar_collections.dart';
import '../../../../core/services/voice_memo_service.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Future<List<Task>> getAll({bool includeArchived = false}) async {
    final query = _isar.taskCollections.where();
    final results = includeArchived
        ? await query.sortByUpdatedAtDesc().findAll()
        : await query.filter().archivedEqualTo(false).sortByUpdatedAtDesc().findAll();
    return results.map(TaskMapper.fromCollection).toList();
  }

  @override
  Future<List<Task>> getToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final results = await _isar.taskCollections
        .filter()
        .archivedEqualTo(false)
        .completedEqualTo(false)
        .dueDateBetween(start, end)
        .findAll();
    return results.map(TaskMapper.fromCollection).toList();
  }

  @override
  Future<List<Task>> getPinned() async {
    final results = await _isar.taskCollections
        .filter()
        .pinnedEqualTo(true)
        .archivedEqualTo(false)
        .findAll();
    return results.map(TaskMapper.fromCollection).toList();
  }

  @override
  Future<List<Task>> getCompleted() async {
    final results = await _isar.taskCollections
        .filter()
        .completedEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();
    return results.map(TaskMapper.fromCollection).toList();
  }

  @override
  Future<List<Task>> search(String query) async {
    if (query.isEmpty) return getAll();
    final lower = query.toLowerCase();
    final results = await _isar.taskCollections
        .filter()
        .archivedEqualTo(false)
        .findAll();
    return results
        .map(TaskMapper.fromCollection)
        .where((t) =>
            t.title.toLowerCase().contains(lower) ||
            (t.description?.toLowerCase().contains(lower) ?? false))
        .toList();
  }

  @override
  Future<Task?> getById(String id) async {
    final result =
        await _isar.taskCollections.filter().uuidEqualTo(id).findFirst();
    return result != null ? TaskMapper.fromCollection(result) : null;
  }

  @override
  Future<void> save(Task task) async {
    await _isar.writeTxn(() async {
      final existing =
          await _isar.taskCollections.filter().uuidEqualTo(task.id).findFirst();
      final collection = TaskMapper.toCollection(task);
      if (existing != null) collection.id = existing.id;
      await _isar.taskCollections.put(collection);
    });
  }

  @override
  Future<void> delete(String id) async {
    String? voicePath;
    await _isar.writeTxn(() async {
      final existing =
          await _isar.taskCollections.filter().uuidEqualTo(id).findFirst();
      if (existing != null) {
        voicePath = existing.voicePath;
        await _isar.taskCollections.delete(existing.id);
      }
    });
    await VoiceMemoService.deleteIfExists(voicePath);
  }

  @override
  Future<void> toggleComplete(String id) async {
    final task = await getById(id);
    if (task == null) return;
    await save(task.copyWith(
      completed: !task.completed,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Task> duplicate(String id) async {
    final task = await getById(id);
    if (task == null) throw StateError('Task not found');
    final now = DateTime.now();
    final copy = task.copyWith(
      id: const Uuid().v4(),
      title: '${task.title} (copy)',
      completed: false,
      createdAt: now,
      updatedAt: now,
    );
    await save(copy);
    return copy;
  }
}
