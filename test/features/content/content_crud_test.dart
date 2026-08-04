import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:skytask/core/database/isar_collections.dart'
    hide TaskPriority, RepeatType, NotificationOffset;
import 'package:skytask/core/services/private_crypto_service.dart';
import 'package:skytask/features/ideas/data/repositories/idea_repository_impl.dart';
import 'package:skytask/features/ideas/domain/entities/idea.dart';
import 'package:skytask/features/notes/data/repositories/note_repository_impl.dart';
import 'package:skytask/features/notes/domain/entities/note.dart';
import 'package:skytask/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:skytask/features/reminders/domain/entities/reminder.dart';
import 'package:skytask/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:skytask/features/tasks/domain/entities/task.dart';

/// Full create / read / update / delete coverage against a real temp Isar DB.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  Isar? isar;
  late TaskRepositoryImpl tasks;
  late ReminderRepositoryImpl reminders;
  late IdeaRepositoryImpl ideas;
  late NoteRepositoryImpl notes;

  setUpAll(() async {
    // Host `flutter test` needs the Isar core dylib next to the project.
    final dylib = File('libisar.dylib');
    if (!dylib.existsSync()) {
      final cached = File(
        '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib',
      );
      if (cached.existsSync()) {
        await cached.copy(dylib.path);
      }
    }
    PrivateCryptoService.instance.debugInitWithKey(Uint8List(32));
  });

  tearDownAll(() {
    PrivateCryptoService.instance.debugReset();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('skytask_crud_');
    final db = await Isar.open(
      [
        TaskCollectionSchema,
        ReminderCollectionSchema,
        IdeaCollectionSchema,
        NoteCollectionSchema,
      ],
      directory: tempDir.path,
      name: 'crud_test',
      inspector: false,
    );
    isar = db;
    tasks = TaskRepositoryImpl(db);
    reminders = ReminderRepositoryImpl(db);
    ideas = IdeaRepositoryImpl(db);
    notes = NoteRepositoryImpl(db);
  });

  tearDown(() async {
    final db = isar;
    if (db != null && db.isOpen) {
      await db.close(deleteFromDisk: true);
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Tasks CRUD', () {
    test('create, read, update, archive, complete, duplicate, delete', () async {
      final now = DateTime(2026, 8, 4, 12);
      final task = Task(
        id: 'task-1',
        title: 'Buy milk',
        description: '2 litres',
        priority: TaskPriority.high,
        category: 'Personal',
        tags: const ['errand'],
        dueDate: DateTime(2026, 8, 5),
        createdAt: now,
        updatedAt: now,
      );

      await tasks.save(task);
      expect((await tasks.getAll()).single.title, 'Buy milk');
      expect((await tasks.getById('task-1'))?.description, '2 litres');

      await tasks.save(
        task.copyWith(title: 'Buy oat milk', updatedAt: now.add(const Duration(minutes: 1))),
      );
      expect((await tasks.getById('task-1'))?.title, 'Buy oat milk');

      await tasks.toggleComplete('task-1');
      expect((await tasks.getById('task-1'))?.completed, isTrue);
      expect((await tasks.getCompleted()).length, 1);

      await tasks.save(
        (await tasks.getById('task-1'))!.copyWith(
          pinned: true,
          completed: false,
          updatedAt: DateTime.now(),
        ),
      );
      expect((await tasks.getPinned()).length, 1);

      final copy = await tasks.duplicate('task-1');
      expect(copy.id, isNot('task-1'));
      expect(copy.title, contains('(copy)'));
      expect((await tasks.getAll()).length, 2);

      await tasks.save(
        (await tasks.getById('task-1'))!.copyWith(archived: true),
      );
      expect((await tasks.getAll()).length, 1); // archived hidden
      expect((await tasks.getAll(includeArchived: true)).length, 2);

      await tasks.delete('task-1');
      await tasks.delete(copy.id);
      expect(await tasks.getAll(includeArchived: true), isEmpty);
    });

    test('private task encrypts at rest and reveals on read', () async {
      final now = DateTime.now();
      await tasks.save(
        Task(
          id: 'priv-1',
          title: 'Secret plan',
          description: 'classified',
          isPrivate: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final raw = await isar!.taskCollections
          .filter()
          .uuidEqualTo('priv-1')
          .findFirst();
      expect(raw!.title.startsWith('enc:v1:'), isTrue);
      expect(raw.description!.startsWith('enc:v1:'), isTrue);

      final loaded = await tasks.getById('priv-1');
      expect(loaded!.title, 'Secret plan');
      expect(loaded.description, 'classified');
      expect(loaded.isPrivate, isTrue);

      await tasks.delete('priv-1');
    });

    test('search matches title and description', () async {
      final now = DateTime.now();
      await tasks.save(
        Task(id: 's1', title: 'Alpha', description: 'findme', createdAt: now, updatedAt: now),
      );
      await tasks.save(
        Task(id: 's2', title: 'Beta', createdAt: now, updatedAt: now),
      );
      final hits = await tasks.search('findme');
      expect(hits.map((t) => t.id), ['s1']);
      await tasks.delete('s1');
      await tasks.delete('s2');
    });
  });

  group('Reminders CRUD', () {
    test('create, update, complete flag, delete', () async {
      final now = DateTime.now();
      final when = now.add(const Duration(hours: 2));
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Dentist',
        description: 'Bring card',
        reminderDateTime: when,
        notificationOffset: NotificationOffset.tenMinutesBefore,
        createdAt: now,
        updatedAt: now,
      );

      await reminders.save(reminder);
      expect((await reminders.getAll()).single.title, 'Dentist');
      expect((await reminders.getById('rem-1'))?.fireDateTime,
          when.subtract(const Duration(minutes: 10)));

      await reminders.save(
        reminder.copyWith(title: 'Dentist checkup', isCompleted: true),
      );
      expect((await reminders.getById('rem-1'))?.isCompleted, isTrue);
      expect((await reminders.getById('rem-1'))?.title, 'Dentist checkup');

      await reminders.delete('rem-1');
      expect(await reminders.getAll(), isEmpty);
    });

    test('private reminder encrypts title/description', () async {
      final now = DateTime.now();
      await reminders.save(
        Reminder(
          id: 'rem-priv',
          title: 'Private meet',
          description: 'hidden',
          reminderDateTime: now.add(const Duration(days: 1)),
          isPrivate: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final raw = await isar!.reminderCollections
          .filter()
          .uuidEqualTo('rem-priv')
          .findFirst();
      expect(raw!.title.startsWith('enc:v1:'), isTrue);
      final loaded = await reminders.getById('rem-priv');
      expect(loaded!.title, 'Private meet');
      await reminders.delete('rem-priv');
    });
  });

  group('Ideas CRUD', () {
    test('create, update, delete', () async {
      final now = DateTime.now();
      await ideas.save(
        Idea(
          id: 'idea-1',
          title: 'App idea',
          content: 'Backup to folder',
          tags: const ['product'],
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect((await ideas.getAll()).single.content, 'Backup to folder');

      await ideas.save(
        Idea(
          id: 'idea-1',
          title: 'App idea v2',
          content: 'Updated',
          createdAt: now,
          updatedAt: now.add(const Duration(minutes: 1)),
        ),
      );
      expect((await ideas.getById('idea-1'))?.title, 'App idea v2');

      await ideas.delete('idea-1');
      expect(await ideas.getAll(), isEmpty);
    });
  });

  group('Notes CRUD', () {
    test('create, update, delete', () async {
      final now = DateTime.now();
      await notes.save(
        Note(
          id: 'note-1',
          title: 'Meeting notes',
          content: 'Discuss release',
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect((await notes.getAll()).single.title, 'Meeting notes');

      await notes.save(
        Note(
          id: 'note-1',
          title: 'Meeting notes',
          content: 'Ship 1.4.1',
          createdAt: now,
          updatedAt: now.add(const Duration(minutes: 2)),
        ),
      );
      expect((await notes.getById('note-1'))?.content, 'Ship 1.4.1');

      await notes.delete('note-1');
      expect(await notes.getAll(), isEmpty);
    });
  });
}
