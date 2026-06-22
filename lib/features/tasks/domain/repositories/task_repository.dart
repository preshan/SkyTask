import '../entities/task.dart';

abstract class TaskRepository {
  Future<List<Task>> getAll({bool includeArchived = false});
  Future<List<Task>> getToday();
  Future<List<Task>> getPinned();
  Future<List<Task>> getCompleted();
  Future<List<Task>> search(String query);
  Future<Task?> getById(String id);
  Future<void> save(Task task);
  Future<void> delete(String id);
  Future<void> toggleComplete(String id);
  Future<Task> duplicate(String id);
}
