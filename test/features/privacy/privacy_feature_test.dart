import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skytask/core/constants/task_categories.dart';
import 'package:skytask/core/utils/pbkdf2.dart';
import 'package:skytask/features/privacy/data/pin_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pbkdf2HmacSha256', () {
    test('is deterministic for same inputs', () {
      final a = pbkdf2HmacSha256(
        password: '1234'.codeUnits,
        salt: List<int>.filled(16, 7),
        iterations: 1000,
        length: 32,
      );
      final b = pbkdf2HmacSha256(
        password: '1234'.codeUnits,
        salt: List<int>.filled(16, 7),
        iterations: 1000,
        length: 32,
      );
      expect(a, orderedEquals(b));
      expect(a.length, 32);
    });

    test('changes when password changes', () {
      final a = pbkdf2HmacSha256(
        password: '1234'.codeUnits,
        salt: List<int>.filled(16, 1),
        iterations: 1000,
        length: 32,
      );
      final b = pbkdf2HmacSha256(
        password: '4321'.codeUnits,
        salt: List<int>.filled(16, 1),
        iterations: 1000,
        length: 32,
      );
      expect(a, isNot(orderedEquals(b)));
    });
  });

  group('TaskCategories', () {
    test('normalize trims and capitalizes', () {
      expect(TaskCategories.normalize('  health '), 'Health');
      expect(TaskCategories.isDefault(TaskCategories.work), isTrue);
      expect(TaskCategories.isDefault(TaskCategories.personal), isTrue);
      expect(TaskCategories.isDefault('Health'), isFalse);
    });

    test('custom categories roundtrip via prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await TaskCategories.saveCustom(prefs, ['Health', 'Study']);
      final loaded = TaskCategories.loadCustom(prefs);
      expect(loaded, containsAll(['Health', 'Study']));
    });

    test('ordered includes defaults and custom', () {
      final ordered = TaskCategories.ordered(
        custom: ['Health'],
        usedLabels: const [],
      );
      expect(ordered, contains(TaskCategories.work));
      expect(ordered, contains(TaskCategories.personal));
      expect(ordered, contains('Health'));
    });
  });

  group('PinStorageService (memory store)', () {
    setUp(() {
      PinStorageService.debugUseMemoryStore();
    });

    tearDown(() {
      PinStorageService.debugDisableMemoryStore();
    });

    test('savePin / verifyPin / biometric switch keeps PIN', () async {
      final pin = PinStorageService.instance;
      await pin.clear();

      await pin.savePin('2580');
      expect(await pin.getAuthMethod(), AuthMethod.pin);
      expect(await pin.hasPin(), isTrue);
      expect(await pin.verifyPin('2580'), isTrue);
      expect(await pin.verifyPin('0000'), isFalse);

      await pin.setBiometricMethod();
      expect(await pin.getAuthMethod(), AuthMethod.biometric);
      expect(await pin.hasPin(), isTrue);
      expect(await pin.verifyPin('2580'), isTrue);

      await pin.setPinMethod();
      expect(await pin.getAuthMethod(), AuthMethod.pin);

      await pin.clear();
      expect(await pin.hasPin(), isFalse);
      expect(await pin.getAuthMethod(), isNull);
    });
  });
}
