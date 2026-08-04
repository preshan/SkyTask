import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skytask/features/backup/data/backup_crypto.dart';
import 'package:skytask/features/backup/data/backup_folder_service.dart';
import 'package:skytask/features/backup/data/backup_models.dart';

void main() {
  group('BackupCrypto', () {
    Uint8List gzipJson(Map<String, dynamic> map) {
      final jsonBytes = utf8.encode(jsonEncode(map));
      return Uint8List.fromList(gzip.encode(jsonBytes));
    }

    test('plain pack/unpack roundtrips gzip JSON', () {
      final payload = gzipJson({'version': 1, 'hello': 'world'});
      final packed = BackupCrypto.pack(gzipPayload: payload);
      expect(BackupCrypto.looksLikeBackup(packed), isTrue);
      expect(BackupCrypto.isPasswordProtected(packed), isFalse);

      final unzipped = BackupCrypto.unpack(packed);
      final map = jsonDecode(utf8.decode(gzip.decode(unzipped)))
          as Map<String, dynamic>;
      expect(map['hello'], 'world');
    });

    test('password pack requires password and rejects wrong one', () {
      final payload = gzipJson({'secret': true});
      final packed = BackupCrypto.pack(
        gzipPayload: payload,
        password: 'correct-horse',
      );
      expect(BackupCrypto.isPasswordProtected(packed), isTrue);

      expect(
        () => BackupCrypto.unpack(packed),
        throwsA(isA<BackupPasswordException>()),
      );
      expect(
        () => BackupCrypto.unpack(packed, password: 'wrong'),
        throwsA(isA<BackupPasswordException>()),
      );

      final unzipped =
          BackupCrypto.unpack(packed, password: 'correct-horse');
      final map = jsonDecode(utf8.decode(gzip.decode(unzipped)))
          as Map<String, dynamic>;
      expect(map['secret'], isTrue);
    });

    test('rejects non-backup bytes', () {
      expect(BackupCrypto.looksLikeBackup(Uint8List.fromList([1, 2, 3])), isFalse);
      expect(
        () => BackupCrypto.unpack(Uint8List.fromList(utf8.encode('not-a-bak'))),
        throwsA(isA<FormatException>()),
      );
    });

    test('magic header is SKYTBAK1', () {
      final packed = BackupCrypto.pack(gzipPayload: gzipJson({'v': 1}));
      expect(utf8.decode(packed.sublist(0, 8)), 'SKYTBAK1');
    });
  });

  group('BackupPayload', () {
    test('toJson/fromJson preserves collections and prefs', () {
      final original = BackupPayload(
        version: 1,
        exportedAt: '2026-08-04T12:00:00Z',
        appVersion: '1.4.1+10',
        tasks: [
          {'id': 't1', 'title': 'Buy milk', 'isPrivate': false},
        ],
        reminders: [
          {'id': 'r1', 'title': 'Call', 'isPrivate': true},
        ],
        ideas: [
          {'id': 'i1', 'title': 'App idea'},
        ],
        notes: [
          {'id': 'n1', 'title': 'Note'},
        ],
        prefs: {
          'theme_mode': 'dark',
          'custom_task_categories': ['Health'],
        },
        voices: {'voice_memos/a.m4a': 'YmFzZTY0'},
      );

      final restored = BackupPayload.fromJson(original.toJson());
      expect(restored.version, 1);
      expect(restored.appVersion, '1.4.1+10');
      expect(restored.tasks.single['title'], 'Buy milk');
      expect(restored.reminders.single['isPrivate'], isTrue);
      expect(restored.ideas.single['id'], 'i1');
      expect(restored.notes.single['id'], 'n1');
      expect(restored.prefs['theme_mode'], 'dark');
      expect(restored.voices['voice_memos/a.m4a'], 'YmFzZTY0');
    });

    test('fromJson tolerates missing lists', () {
      final restored = BackupPayload.fromJson({'version': 1});
      expect(restored.tasks, isEmpty);
      expect(restored.voices, isEmpty);
      expect(restored.prefs, isEmpty);
    });
  });

  group('BackupFolderService', () {
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('skytask_bak_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('flags Alarms / Ringtones as restricted', () {
      final svc = BackupFolderService.instance;
      expect(svc.isLikelyRestricted('/storage/emulated/0/Alarms'), isTrue);
      expect(svc.isLikelyRestricted('/storage/emulated/0/Ringtones'), isTrue);
      expect(svc.isLikelyRestricted('/storage/emulated/0/Download'), isFalse);
      expect(svc.isLikelyRestricted(tempDir.path), isFalse);
    });

    test('canWriteTo succeeds for temp directory', () async {
      final ok = await BackupFolderService.instance.canWriteTo(tempDir.path);
      expect(ok, isTrue);
    });

    test('canWriteTo fails for restricted names', () async {
      final alarms = Directory('${tempDir.path}/Alarms');
      await alarms.create();
      final ok = await BackupFolderService.instance.canWriteTo(alarms.path);
      expect(ok, isFalse);
    });

    test('persists and clears folder path in prefs', () async {
      final svc = BackupFolderService.instance;
      await svc.setPath(tempDir.path);
      expect(await svc.getPath(), tempDir.path);
      expect(svc.displayLabel(tempDir.path), isNot(contains('Not set')));
      await svc.clear();
      expect(await svc.getPath(), isNull);
      expect(svc.displayLabel(null), contains('Not set'));
    });
  });

  group('Backup envelope end-to-end shape', () {
    test('encrypted file then decrypt yields BackupPayload fields', () {
      final payload = BackupPayload(
        version: 1,
        exportedAt: 'now',
        appVersion: '1.4.1+10',
        tasks: [
          {'id': 'abc', 'title': 'Task'},
        ],
        reminders: const [],
        ideas: const [],
        notes: const [],
        prefs: const {'theme_mode': 'system'},
        voices: const {},
      );
      final gzipped = Uint8List.fromList(
        gzip.encode(utf8.encode(jsonEncode(payload.toJson()))),
      );
      final fileBytes = BackupCrypto.pack(
        gzipPayload: gzipped,
        password: 'test-pass',
      );

      expect(BackupCrypto.isPasswordProtected(fileBytes), isTrue);
      final raw = BackupCrypto.unpack(fileBytes, password: 'test-pass');
      final restored = BackupPayload.fromJson(
        jsonDecode(utf8.decode(gzip.decode(raw))) as Map<String, dynamic>,
      );
      expect(restored.tasks.single['id'], 'abc');
      expect(restored.prefs['theme_mode'], 'system');
    });
  });
}
