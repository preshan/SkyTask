import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAll();
  Future<List<Reminder>> getUpcoming();
  Future<List<Reminder>> getPending();
  Future<Reminder?> getById(String id);
  Future<void> save(Reminder reminder);
  Future<void> delete(String id);
}
