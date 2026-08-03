import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/providers.dart';
import '../../features/tasks/domain/entities/task.dart';

/// Task category catalog — Work & Personal by default; users can add more.
abstract final class TaskCategories {
  static const work = 'Work';
  static const personal = 'Personal';
  static const defaults = [work, personal];

  static const _prefsKey = 'custom_task_categories';

  static String normalize(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return personal;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  static bool isDefault(String name) =>
      defaults.any((d) => d.toLowerCase() == name.toLowerCase());

  /// Merge defaults + saved customs + labels seen on tasks, most-used first.
  static List<String> ordered({
    required List<String> custom,
    required List<Task> tasks,
  }) {
    final counts = <String, int>{};
    for (final task in tasks) {
      final key = normalize(task.category);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final byLower = <String, String>{};
    for (final d in defaults) {
      byLower[d.toLowerCase()] = d;
    }
    for (final c in custom) {
      final n = normalize(c);
      byLower.putIfAbsent(n.toLowerCase(), () => n);
    }
    for (final key in counts.keys) {
      byLower.putIfAbsent(key.toLowerCase(), () => key);
    }

    final list = byLower.values.toList();
    list.sort((a, b) {
      final caI = _countIgnoreCase(counts, a);
      final cbI = _countIgnoreCase(counts, b);
      if (caI != cbI) return cbI.compareTo(caI);
      final da = isDefault(a);
      final db = isDefault(b);
      if (da != db) return da ? -1 : 1;
      // Stable default order: Work then Personal
      if (da && db) {
        return defaults.indexOf(a).compareTo(defaults.indexOf(b));
      }
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return list;
  }

  static int _countIgnoreCase(Map<String, int> counts, String name) {
    var total = 0;
    final lower = name.toLowerCase();
    for (final e in counts.entries) {
      if (e.key.toLowerCase() == lower) total += e.value;
    }
    return total;
  }

  static List<String> loadCustom(SharedPreferences prefs) {
    return (prefs.getStringList(_prefsKey) ?? [])
        .map(normalize)
        .where((c) => c.isNotEmpty && !isDefault(c))
        .toList();
  }

  static Future<void> saveCustom(
    SharedPreferences prefs,
    List<String> custom,
  ) async {
    final cleaned = custom
        .map(normalize)
        .where((c) => c.isNotEmpty && !isDefault(c))
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await prefs.setStringList(_prefsKey, cleaned);
  }
}

final customTaskCategoriesProvider =
    StateNotifierProvider<CustomTaskCategoriesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CustomTaskCategoriesNotifier(prefs);
});

class CustomTaskCategoriesNotifier extends StateNotifier<List<String>> {
  CustomTaskCategoriesNotifier(this._prefs)
      : super(TaskCategories.loadCustom(_prefs));

  final SharedPreferences _prefs;

  Future<void> add(String raw) async {
    final name = TaskCategories.normalize(raw);
    if (name.isEmpty || TaskCategories.isDefault(name)) return;
    if (state.any((c) => c.toLowerCase() == name.toLowerCase())) return;
    final next = [...state, name];
    await TaskCategories.saveCustom(_prefs, next);
    state = TaskCategories.loadCustom(_prefs);
  }

  Future<void> remove(String raw) async {
    final name = TaskCategories.normalize(raw);
    if (TaskCategories.isDefault(name)) return;
    final next =
        state.where((c) => c.toLowerCase() != name.toLowerCase()).toList();
    await TaskCategories.saveCustom(_prefs, next);
    state = TaskCategories.loadCustom(_prefs);
  }
}
