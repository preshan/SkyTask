import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/content_providers.dart';
import '../di/providers.dart';
import '../../features/calendar/presentation/providers/calendar_providers.dart';
import '../../features/ideas/domain/repositories/idea_repository.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/reminders/domain/repositories/reminder_repository.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';

/// Soft pastel category color + display name.
class AppCategory {
  const AppCategory({required this.name, required this.color});

  final String name;
  final int color;

  Color get swatch => Color(color);

  Map<String, dynamic> toJson() => {'name': name, 'color': color};

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    final name = TaskCategories.normalize(json['name']?.toString() ?? '');
    final raw = json['color'];
    final color = raw is int
        ? raw
        : int.tryParse(raw?.toString() ?? '') ??
            TaskCategories.pastelForName(name);
    return AppCategory(name: name, color: color);
  }

  AppCategory copyWith({String? name, int? color}) => AppCategory(
        name: name ?? this.name,
        color: color ?? this.color,
      );
}

/// Shared category catalog for tasks, reminders, ideas, and notes.
abstract final class TaskCategories {
  static const work = 'Work';
  static const personal = 'Personal';
  static const defaults = [work, personal];

  /// Legacy string-list key (migrated on read).
  static const prefsKey = 'custom_task_categories';

  /// JSON list of `{name, color}` for customs.
  static const prefsKeyV2 = 'custom_task_categories_v2';

  /// Optional color overrides for Work / Personal.
  static const defaultColorsKey = 'default_category_colors';

  /// Soft pastels (not saturated brand greens/reds).
  static const pastelPalette = <int>[
    0xFFB3D4F0, // soft blue
    0xFFFFE0B2, // soft amber
    0xFFC8E6C9, // mint
    0xFFE1BEE7, // lavender
    0xFFFFCCBC, // peach
    0xFFF8BBD0, // soft rose
    0xFFB2DFDB, // soft teal
    0xFFD1C4E9, // soft lilac
    0xFFFFF9C4, // soft lemon
    0xFFB3E5FC, // sky
    0xFFDCEDC8, // light green
    0xFFFFE0E6, // blush
  ];

  static const workColor = 0xFFB3D4F0;
  static const personalColor = 0xFFFFE0B2;

  static String normalize(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return personal;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  static bool isDefault(String name) =>
      defaults.any((d) => d.toLowerCase() == name.toLowerCase());

  static int pastelForName(String name) {
    final n = normalize(name);
    if (n.toLowerCase() == work.toLowerCase()) return workColor;
    if (n.toLowerCase() == personal.toLowerCase()) return personalColor;
    final idx = n.toLowerCase().hashCode.abs() % pastelPalette.length;
    return pastelPalette[idx];
  }

  static int randomPastel({Iterable<int> avoid = const []}) {
    final avoided = avoid.toSet();
    final pool =
        pastelPalette.where((c) => !avoided.contains(c)).toList(growable: false);
    final choices = pool.isEmpty ? pastelPalette : pool;
    return choices[Random().nextInt(choices.length)];
  }

  /// Resolve display color for any label.
  static int colorFor(
    String name, {
    List<AppCategory> custom = const [],
    Map<String, int> defaultOverrides = const {},
  }) {
    final n = normalize(name);
    final lower = n.toLowerCase();
    for (final c in custom) {
      if (c.name.toLowerCase() == lower) return c.color;
    }
    if (defaultOverrides.containsKey(lower)) {
      return defaultOverrides[lower]!;
    }
    // Prefer canonical keys for defaults.
    if (lower == work.toLowerCase()) {
      return defaultOverrides[work.toLowerCase()] ?? workColor;
    }
    if (lower == personal.toLowerCase()) {
      return defaultOverrides[personal.toLowerCase()] ?? personalColor;
    }
    return pastelForName(n);
  }

  static Map<String, int> loadDefaultColorOverrides(SharedPreferences prefs) {
    final raw = prefs.getString(defaultColorsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in map.entries)
          e.key.toLowerCase(): e.value is int
              ? e.value as int
              : int.tryParse(e.value.toString()) ?? pastelForName(e.key),
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveDefaultColorOverrides(
    SharedPreferences prefs,
    Map<String, int> overrides,
  ) async {
    final cleaned = <String, int>{};
    for (final e in overrides.entries) {
      if (isDefault(e.key)) {
        cleaned[normalize(e.key).toLowerCase()] = e.value;
      }
    }
    await prefs.setString(defaultColorsKey, jsonEncode(cleaned));
  }

  /// Merge defaults + saved customs + labels seen on content, most-used first.
  static List<AppCategory> ordered({
    required List<AppCategory> custom,
    required Iterable<String> usedLabels,
    Map<String, int> defaultOverrides = const {},
  }) {
    final counts = <String, int>{};
    for (final raw in usedLabels) {
      final key = normalize(raw);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final byLower = <String, AppCategory>{};
    for (final d in defaults) {
      byLower[d.toLowerCase()] = AppCategory(
        name: d,
        color: colorFor(d, custom: custom, defaultOverrides: defaultOverrides),
      );
    }
    for (final c in custom) {
      final n = normalize(c.name);
      byLower.putIfAbsent(
        n.toLowerCase(),
        () => AppCategory(name: n, color: c.color),
      );
    }
    for (final key in counts.keys) {
      byLower.putIfAbsent(
        key.toLowerCase(),
        () => AppCategory(
          name: key,
          color: colorFor(key, custom: custom, defaultOverrides: defaultOverrides),
        ),
      );
    }

    final list = byLower.values.toList();
    list.sort((a, b) {
      final caI = _countIgnoreCase(counts, a.name);
      final cbI = _countIgnoreCase(counts, b.name);
      if (caI != cbI) return cbI.compareTo(caI);
      final da = isDefault(a.name);
      final db = isDefault(b.name);
      if (da != db) return da ? -1 : 1;
      if (da && db) {
        return defaults.indexOf(a.name).compareTo(defaults.indexOf(b.name));
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
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

  /// Load customs (migrates legacy string list once).
  static List<AppCategory> loadCustom(SharedPreferences prefs) {
    final v2 = prefs.getString(prefsKeyV2);
    if (v2 != null && v2.isNotEmpty) {
      try {
        final list = jsonDecode(v2) as List<dynamic>;
        return list
            .whereType<Map>()
            .map((e) => AppCategory.fromJson(Map<String, dynamic>.from(e)))
            .where((c) => c.name.isNotEmpty && !isDefault(c.name))
            .toList();
      } catch (_) {
        // Fall through to legacy.
      }
    }

    final legacy = prefs.getStringList(prefsKey) ?? [];
    final migrated = legacy
        .map(normalize)
        .where((c) => c.isNotEmpty && !isDefault(c))
        .map((n) => AppCategory(name: n, color: pastelForName(n)))
        .toList();
    if (migrated.isNotEmpty) {
      unawaited(saveCustom(prefs, migrated));
    }
    return migrated;
  }

  /// Names only (backup / simple callers).
  static List<String> loadCustomNames(SharedPreferences prefs) =>
      loadCustom(prefs).map((c) => c.name).toList();

  static Future<void> saveCustom(
    SharedPreferences prefs,
    List<AppCategory> custom,
  ) async {
    final cleaned = <String, AppCategory>{};
    for (final c in custom) {
      final n = normalize(c.name);
      if (n.isEmpty || isDefault(n)) continue;
      cleaned[n.toLowerCase()] = AppCategory(name: n, color: c.color);
    }
    final list = cleaned.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await prefs.setString(
      prefsKeyV2,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    // Keep legacy names in sync for older backup tooling.
    await prefs.setStringList(prefsKey, list.map((e) => e.name).toList());
  }

  /// Import customs from backup JSON (v2 maps or legacy strings).
  static Future<void> importCustomFromBackup(
    SharedPreferences prefs,
    dynamic raw,
  ) async {
    if (raw is! List) return;
    final cats = <AppCategory>[];
    for (final item in raw) {
      if (item is Map) {
        cats.add(AppCategory.fromJson(Map<String, dynamic>.from(item)));
      } else {
        final n = normalize(item.toString());
        if (n.isNotEmpty && !isDefault(n)) {
          cats.add(AppCategory(name: n, color: pastelForName(n)));
        }
      }
    }
    await saveCustom(prefs, cats);
  }
}

final customTaskCategoriesProvider = StateNotifierProvider<
    CustomTaskCategoriesNotifier, List<AppCategory>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CustomTaskCategoriesNotifier(prefs);
});

final defaultCategoryColorsProvider =
    StateNotifierProvider<DefaultCategoryColorsNotifier, Map<String, int>>(
        (ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DefaultCategoryColorsNotifier(prefs);
});

class DefaultCategoryColorsNotifier extends StateNotifier<Map<String, int>> {
  DefaultCategoryColorsNotifier(this._prefs)
      : super(TaskCategories.loadDefaultColorOverrides(_prefs));

  final SharedPreferences _prefs;

  Future<void> setColor(String name, int color) async {
    if (!TaskCategories.isDefault(name)) return;
    final key = TaskCategories.normalize(name).toLowerCase();
    final next = {...state, key: color};
    await TaskCategories.saveDefaultColorOverrides(_prefs, next);
    state = TaskCategories.loadDefaultColorOverrides(_prefs);
  }
}

class CustomTaskCategoriesNotifier extends StateNotifier<List<AppCategory>> {
  CustomTaskCategoriesNotifier(this._prefs)
      : super(TaskCategories.loadCustom(_prefs));

  final SharedPreferences _prefs;

  Future<void> add(String raw, {int? color}) async {
    final name = TaskCategories.normalize(raw);
    if (name.isEmpty || TaskCategories.isDefault(name)) return;
    if (state.any((c) => c.name.toLowerCase() == name.toLowerCase())) return;
    final usedColors = state.map((c) => c.color);
    final next = [
      ...state,
      AppCategory(
        name: name,
        color: color ?? TaskCategories.randomPastel(avoid: usedColors),
      ),
    ];
    await TaskCategories.saveCustom(_prefs, next);
    state = TaskCategories.loadCustom(_prefs);
  }

  Future<void> update({
    required String oldName,
    String? name,
    int? color,
  }) async {
    final from = TaskCategories.normalize(oldName);
    if (TaskCategories.isDefault(from)) return;
    final to = TaskCategories.normalize(name ?? from);
    if (to.isEmpty || TaskCategories.isDefault(to)) return;

    final next = <AppCategory>[];
    for (final c in state) {
      if (c.name.toLowerCase() == from.toLowerCase()) {
        next.add(AppCategory(name: to, color: color ?? c.color));
      } else if (c.name.toLowerCase() != to.toLowerCase()) {
        next.add(c);
      }
    }
    await TaskCategories.saveCustom(_prefs, next);
    state = TaskCategories.loadCustom(_prefs);
  }

  Future<void> remove(String raw) async {
    final name = TaskCategories.normalize(raw);
    if (TaskCategories.isDefault(name)) return;
    final next =
        state.where((c) => c.name.toLowerCase() != name.toLowerCase()).toList();
    await TaskCategories.saveCustom(_prefs, next);
    state = TaskCategories.loadCustom(_prefs);
  }
}

/// Category labels used across tasks, reminders, ideas, and notes.
final categoryUsageLabelsProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(tasksRevisionProvider);
  ref.watch(remindersRevisionProvider);
  ref.watch(ideasRevisionProvider);
  ref.watch(notesRevisionProvider);

  final labels = <String>[];

  final tasks = await (await ref.read(taskRepositoryProvider.future))
      .getAll(includeArchived: true);
  labels.addAll(tasks.map((t) => t.category));

  final reminders =
      await (await ref.read(reminderRepositoryProvider.future)).getAll();
  labels.addAll(reminders.map((r) => r.category));

  final ideas = await (await ref.read(ideaRepositoryProvider.future)).getAll();
  labels.addAll(ideas.map((i) => i.category));

  final notes = await (await ref.read(noteRepositoryProvider.future)).getAll();
  labels.addAll(notes.map((n) => n.category));

  return labels;
});

/// Bulk-reassign [from] → [to] across all content types. Returns updated count.
Future<int> reassignCategoryAcrossContent({
  required String from,
  required String to,
  required TaskRepository tasks,
  required ReminderRepository reminders,
  required IdeaRepository ideas,
  required NoteRepository notes,
}) async {
  final src = TaskCategories.normalize(from);
  final dest = TaskCategories.normalize(to);
  if (src.toLowerCase() == dest.toLowerCase()) return 0;

  var count = 0;
  final now = DateTime.now();

  for (final t in await tasks.getAll(includeArchived: true)) {
    if (t.category.toLowerCase() == src.toLowerCase()) {
      await tasks.save(t.copyWith(category: dest, updatedAt: now));
      count++;
    }
  }
  for (final r in await reminders.getAll()) {
    if (r.category.toLowerCase() == src.toLowerCase()) {
      await reminders.save(r.copyWith(category: dest, updatedAt: now));
      count++;
    }
  }
  for (final i in await ideas.getAll()) {
    if (i.category.toLowerCase() == src.toLowerCase()) {
      await ideas.save(i.copyWith(category: dest, updatedAt: now));
      count++;
    }
  }
  for (final n in await notes.getAll()) {
    if (n.category.toLowerCase() == src.toLowerCase()) {
      await notes.save(n.copyWith(category: dest, updatedAt: now));
      count++;
    }
  }
  return count;
}

Future<int> countItemsWithCategory({
  required String category,
  required TaskRepository tasks,
  required ReminderRepository reminders,
  required IdeaRepository ideas,
  required NoteRepository notes,
}) async {
  final key = TaskCategories.normalize(category).toLowerCase();
  var count = 0;
  count += (await tasks.getAll(includeArchived: true))
      .where((t) => t.category.toLowerCase() == key)
      .length;
  count += (await reminders.getAll())
      .where((r) => r.category.toLowerCase() == key)
      .length;
  count +=
      (await ideas.getAll()).where((i) => i.category.toLowerCase() == key).length;
  count +=
      (await notes.getAll()).where((n) => n.category.toLowerCase() == key).length;
  return count;
}
