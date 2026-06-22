import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../database/isar_collections.dart';

/// Opens and manages the local Isar database (offline-first).
class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  Isar? _isar;

  Future<Isar> get db async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    _isar = await _open();
    return _isar!;
  }

  Future<Isar> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        TaskCollectionSchema,
        ReminderCollectionSchema,
        IdeaCollectionSchema,
        NoteCollectionSchema,
      ],
      directory: dir.path,
      name: AppConstants.isarName,
    );
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
