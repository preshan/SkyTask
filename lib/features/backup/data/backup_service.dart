import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/constants/task_categories.dart';
import '../../../core/database/isar_collections.dart'
    hide TaskPriority, RepeatType, NotificationOffset;
import '../../../core/services/alarm_service.dart';
import '../../../core/services/isar_service.dart';
import '../../../core/services/voice_memo_service.dart';
import '../../../core/utils/stable_notification_id.dart';
import '../../ideas/data/mappers/idea_mapper.dart';
import '../../ideas/domain/entities/idea.dart';
import '../../notes/data/mappers/note_mapper.dart';
import '../../notes/domain/entities/note.dart';
import '../../reminders/data/mappers/reminder_mapper.dart';
import '../../reminders/domain/entities/reminder.dart';
import '../../tasks/data/mappers/task_mapper.dart';
import '../../tasks/domain/entities/task.dart';
import 'backup_crypto.dart';
import 'backup_models.dart';

/// Builds and restores SkyTask `.skytaskbak` archives.
class BackupService {
  BackupService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Creates a backup file under app documents / backups /.
  Future<File> exportToFile({String? password}) async {
    final bytes = await exportBytes(password: password);
    final dir = await _backupDir();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(dir.path, 'SkyTask_backup_$stamp.skytaskbak'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Uint8List> exportBytes({String? password}) async {
    final payload = await _buildPayload();
    final jsonBytes = utf8.encode(jsonEncode(payload.toJson()));
    final gzipped = Uint8List.fromList(gzip.encode(jsonBytes));
    return BackupCrypto.pack(gzipPayload: gzipped, password: password);
  }

  Future<void> importBytes(
    Uint8List bytes, {
    String? password,
    required BackupImportMode mode,
  }) async {
    final gzipped = BackupCrypto.unpack(bytes, password: password);
    final jsonText = utf8.decode(gzip.decode(gzipped));
    final map = jsonDecode(jsonText) as Map<String, dynamic>;
    final payload = BackupPayload.fromJson(map);
    await _applyPayload(payload, mode: mode);
    await AlarmService.instance.rescheduleAllReminders();
  }

  Future<void> importFile(
    File file, {
    String? password,
    required BackupImportMode mode,
  }) async {
    final bytes = await file.readAsBytes();
    await importBytes(
      Uint8List.fromList(bytes),
      password: password,
      mode: mode,
    );
  }

  Future<BackupPayload> _buildPayload() async {
    final isar = await IsarService.instance.db;
    final tasks = await isar.taskCollections.where().findAll();
    final reminders = await isar.reminderCollections.where().findAll();
    final ideas = await isar.ideaCollections.where().findAll();
    final notes = await isar.noteCollections.where().findAll();

    final voices = <String, String>{};
    Future<String?> packVoice(String? absolute) async {
      if (absolute == null || absolute.isEmpty) return null;
      final file = File(absolute);
      if (!await file.exists()) return null;
      final name = p.basename(absolute);
      final rel = 'voice_memos/$name';
      voices.putIfAbsent(rel, () => base64Encode(file.readAsBytesSync()));
      return rel;
    }

    final taskMaps = <Map<String, dynamic>>[];
    for (final c in tasks) {
      final t = TaskMapper.fromCollection(c);
      final voiceRel = await packVoice(t.voicePath);
      taskMaps.add(_taskToJson(t, voiceRel));
    }

    final reminderMaps = <Map<String, dynamic>>[];
    for (final c in reminders) {
      final r = ReminderMapper.fromCollection(c);
      final voiceRel = await packVoice(r.voicePath);
      reminderMaps.add(_reminderToJson(r, voiceRel));
    }

    final ideaMaps = <Map<String, dynamic>>[];
    for (final c in ideas) {
      final i = IdeaMapper.fromCollection(c);
      final voiceRel = await packVoice(i.voicePath);
      ideaMaps.add(_ideaToJson(i, voiceRel));
    }

    final noteMaps = <Map<String, dynamic>>[];
    for (final c in notes) {
      final n = NoteMapper.fromCollection(c);
      final voiceRel = await packVoice(n.voicePath);
      noteMaps.add(_noteToJson(n, voiceRel));
    }

    final prefs = await _preferences;
    return BackupPayload(
      version: 1,
      exportedAt: DateTime.now().toUtc().toIso8601String(),
      appVersion: AppInfo.versionLabel,
      tasks: taskMaps,
      reminders: reminderMaps,
      ideas: ideaMaps,
      notes: noteMaps,
      prefs: {
        AppConstants.themeModeKey: prefs.getString(AppConstants.themeModeKey),
        'custom_task_categories': TaskCategories.loadCustom(prefs),
        AppConstants.captureVoiceSavesKey:
            prefs.getInt(AppConstants.captureVoiceSavesKey) ?? 0,
        AppConstants.captureTypedDescSavesKey:
            prefs.getInt(AppConstants.captureTypedDescSavesKey) ?? 0,
      },
      voices: voices,
    );
  }

  Future<void> _applyPayload(
    BackupPayload payload, {
    required BackupImportMode mode,
  }) async {
    final isar = await IsarService.instance.db;
    final voiceDir = await VoiceMemoService.directory();

    // Restore voice files first so paths resolve.
    for (final entry in payload.voices.entries) {
      final name = p.basename(entry.key);
      final target = File(p.join(voiceDir.path, name));
      await target.writeAsBytes(base64Decode(entry.value), flush: true);
    }

    String? absoluteVoice(String? rel) {
      if (rel == null || rel.isEmpty) return null;
      return p.join(voiceDir.path, p.basename(rel));
    }

    if (mode == BackupImportMode.replace) {
      await isar.writeTxn(() async {
        await isar.taskCollections.clear();
        await isar.reminderCollections.clear();
        await isar.ideaCollections.clear();
        await isar.noteCollections.clear();
      });
      // Remove orphaned voice files not in backup.
      if (await voiceDir.exists()) {
        final keep = payload.voices.keys.map(p.basename).toSet();
        await for (final entity in voiceDir.list()) {
          if (entity is File && !keep.contains(p.basename(entity.path))) {
            await entity.delete();
          }
        }
      }
    }

    await isar.writeTxn(() async {
      for (final map in payload.tasks) {
        final task = _taskFromJson(map, absoluteVoice);
        await _upsertTask(isar, task);
      }
      for (final map in payload.reminders) {
        final reminder = _reminderFromJson(map, absoluteVoice);
        await _upsertReminder(isar, reminder);
      }
      for (final map in payload.ideas) {
        final idea = _ideaFromJson(map, absoluteVoice);
        await _upsertIdea(isar, idea);
      }
      for (final map in payload.notes) {
        final note = _noteFromJson(map, absoluteVoice);
        await _upsertNote(isar, note);
      }
    });

    final prefs = await _preferences;
    final theme = payload.prefs[AppConstants.themeModeKey];
    if (theme is String && theme.isNotEmpty) {
      await prefs.setString(AppConstants.themeModeKey, theme);
    }
    final cats = payload.prefs['custom_task_categories'];
    if (cats is List) {
      await TaskCategories.saveCustom(
        prefs,
        cats.map((e) => e.toString()).toList(),
      );
    }
    final voiceSaves = payload.prefs[AppConstants.captureVoiceSavesKey];
    if (voiceSaves is int) {
      await prefs.setInt(AppConstants.captureVoiceSavesKey, voiceSaves);
    }
    final typedSaves = payload.prefs[AppConstants.captureTypedDescSavesKey];
    if (typedSaves is int) {
      await prefs.setInt(AppConstants.captureTypedDescSavesKey, typedSaves);
    }
  }

  Future<void> _upsertTask(Isar isar, Task task) async {
    final existing =
        await isar.taskCollections.filter().uuidEqualTo(task.id).findFirst();
    final collection = TaskMapper.toCollection(task);
    if (existing != null) collection.id = existing.id;
    await isar.taskCollections.put(collection);
  }

  Future<void> _upsertReminder(Isar isar, Reminder reminder) async {
    final existing = await isar.reminderCollections
        .filter()
        .uuidEqualTo(reminder.id)
        .findFirst();
    // Fresh notification ids after restore — avoid collisions with old device state.
    final withId = reminder.copyWith(
      notificationId: stableNotificationId(reminder.id),
      clearCalendarEventId: true,
      googleEventId: null,
    );
    final collection = ReminderMapper.toCollection(withId);
    if (existing != null) collection.id = existing.id;
    await isar.reminderCollections.put(collection);
  }

  Future<void> _upsertIdea(Isar isar, Idea idea) async {
    final existing =
        await isar.ideaCollections.filter().uuidEqualTo(idea.id).findFirst();
    final collection = IdeaMapper.toCollection(idea);
    if (existing != null) collection.id = existing.id;
    await isar.ideaCollections.put(collection);
  }

  Future<void> _upsertNote(Isar isar, Note note) async {
    final existing =
        await isar.noteCollections.filter().uuidEqualTo(note.id).findFirst();
    final collection = NoteMapper.toCollection(note);
    if (existing != null) collection.id = existing.id;
    await isar.noteCollections.put(collection);
  }

  Future<Directory> _backupDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Map<String, dynamic> _taskToJson(Task t, String? voiceRel) => {
        'id': t.id,
        'title': t.title,
        'description': t.description,
        'priority': t.priority.name,
        'category': t.category,
        'tags': t.tags,
        'dueDate': t.dueDate?.toIso8601String(),
        'completed': t.completed,
        'pinned': t.pinned,
        'archived': t.archived,
        'isPrivate': t.isPrivate,
        'voicePath': voiceRel,
        'createdAt': t.createdAt.toIso8601String(),
        'updatedAt': t.updatedAt.toIso8601String(),
      };

  Task _taskFromJson(
    Map<String, dynamic> m,
    String? Function(String?) absVoice,
  ) {
    return Task(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      description: m['description'] as String?,
      priority: TaskPriority.values.byName(
        m['priority'] as String? ?? TaskPriority.medium.name,
      ),
      category: m['category'] as String? ?? TaskCategories.personal,
      tags: (m['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      dueDate: _parseDate(m['dueDate']),
      completed: m['completed'] as bool? ?? false,
      pinned: m['pinned'] as bool? ?? false,
      archived: m['archived'] as bool? ?? false,
      isPrivate: m['isPrivate'] as bool? ?? false,
      voicePath: absVoice(m['voicePath'] as String?),
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(m['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _reminderToJson(Reminder r, String? voiceRel) => {
        'id': r.id,
        'title': r.title,
        'description': r.description,
        'reminderDateTime': r.reminderDateTime.toIso8601String(),
        'repeatType': r.repeatType.name,
        'notificationOffset': r.notificationOffset.name,
        'customOffsetMinutes': r.customOffsetMinutes,
        'isPrivate': r.isPrivate,
        'isCompleted': r.isCompleted,
        'voicePath': voiceRel,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };

  Reminder _reminderFromJson(
    Map<String, dynamic> m,
    String? Function(String?) absVoice,
  ) {
    return Reminder(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      description: m['description'] as String?,
      reminderDateTime:
          _parseDate(m['reminderDateTime']) ?? DateTime.now(),
      repeatType: RepeatType.values.byName(
        m['repeatType'] as String? ?? RepeatType.none.name,
      ),
      notificationOffset: NotificationOffset.values.byName(
        m['notificationOffset'] as String? ??
            NotificationOffset.atTime.name,
      ),
      customOffsetMinutes: m['customOffsetMinutes'] as int?,
      isPrivate: m['isPrivate'] as bool? ?? false,
      isCompleted: m['isCompleted'] as bool? ?? false,
      voicePath: absVoice(m['voicePath'] as String?),
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(m['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _ideaToJson(Idea i, String? voiceRel) => {
        'id': i.id,
        'title': i.title,
        'content': i.content,
        'tags': i.tags,
        'isPrivate': i.isPrivate,
        'voicePath': voiceRel,
        'createdAt': i.createdAt.toIso8601String(),
        'updatedAt': i.updatedAt.toIso8601String(),
      };

  Idea _ideaFromJson(
    Map<String, dynamic> m,
    String? Function(String?) absVoice,
  ) {
    return Idea(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      content: m['content'] as String? ?? '',
      tags: (m['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isPrivate: m['isPrivate'] as bool? ?? false,
      voicePath: absVoice(m['voicePath'] as String?),
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(m['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _noteToJson(Note n, String? voiceRel) => {
        'id': n.id,
        'title': n.title,
        'content': n.content,
        'attachments': n.attachments,
        'isPrivate': n.isPrivate,
        'voicePath': voiceRel,
        'createdAt': n.createdAt.toIso8601String(),
        'updatedAt': n.updatedAt.toIso8601String(),
      };

  Note _noteFromJson(
    Map<String, dynamic> m,
    String? Function(String?) absVoice,
  ) {
    return Note(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      content: m['content'] as String? ?? '',
      attachments:
          (m['attachments'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isPrivate: m['isPrivate'] as bool? ?? false,
      voicePath: absVoice(m['voicePath'] as String?),
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(m['updatedAt']) ?? DateTime.now(),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
