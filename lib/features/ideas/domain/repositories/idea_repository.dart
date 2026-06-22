import '../entities/idea.dart';

abstract class IdeaRepository {
  Future<List<Idea>> getAll();
  Future<Idea?> getById(String id);
  Future<void> save(Idea idea);
  Future<void> delete(String id);
}
