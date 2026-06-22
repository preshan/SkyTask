import 'package:isar/isar.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../mappers/reminder_mapper.dart';
import '../../../../core/database/isar_collections.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Future<List<Reminder>> getAll() async {
    final results =
        await _isar.reminderCollections.where().sortByReminderDateTime().findAll();
    return results.map(ReminderMapper.fromCollection).toList();
  }

  @override
  Future<List<Reminder>> getUpcoming() async {
    final now = DateTime.now();
    final results = await _isar.reminderCollections
        .filter()
        .reminderDateTimeGreaterThan(now)
        .sortByReminderDateTime()
        .findAll();
    return results.map(ReminderMapper.fromCollection).toList();
  }

  @override
  Future<List<Reminder>> getPending() async {
    final now = DateTime.now();
    final results = await _isar.reminderCollections
        .filter()
        .isCompletedEqualTo(false)
        .reminderDateTimeGreaterThan(now)
        .findAll();
    return results.map(ReminderMapper.fromCollection).toList();
  }

  @override
  Future<Reminder?> getById(String id) async {
    final result =
        await _isar.reminderCollections.filter().uuidEqualTo(id).findFirst();
    return result != null ? ReminderMapper.fromCollection(result) : null;
  }

  @override
  Future<void> save(Reminder reminder) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.reminderCollections
          .filter()
          .uuidEqualTo(reminder.id)
          .findFirst();
      final collection = ReminderMapper.toCollection(reminder);
      if (existing != null) collection.id = existing.id;
      await _isar.reminderCollections.put(collection);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _isar.writeTxn(() async {
      final existing =
          await _isar.reminderCollections.filter().uuidEqualTo(id).findFirst();
      if (existing != null) {
        await _isar.reminderCollections.delete(existing.id);
      }
    });
  }
}
