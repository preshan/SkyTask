import '../entities/quick_link.dart';

abstract class QuickLinkRepository {
  Future<List<QuickLink>> getAll();
  Future<QuickLink?> getById(String id);
  Future<void> save(QuickLink link);
  Future<void> delete(String id);
}
