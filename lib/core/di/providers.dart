import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../services/isar_service.dart';
import '../../features/ideas/data/repositories/idea_repository_impl.dart';
import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/reminders/data/repositories/reminder_repository_impl.dart';
import '../../features/reminders/data/services/reminder_scheduler_service.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';

// ── Bootstrap ──────────────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main()');
});

final isarProvider = FutureProvider<Isar>((ref) async {
  return IsarService.instance.db;
});

// ── Repositories ─────────────────────────────────────────────────────────────

final taskRepositoryProvider = FutureProvider<TaskRepositoryImpl>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return TaskRepositoryImpl(isar);
});

final reminderRepositoryProvider =
    FutureProvider<ReminderRepositoryImpl>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return ReminderRepositoryImpl(isar);
});

final reminderSchedulerProvider =
    FutureProvider<ReminderSchedulerService>((ref) async {
  final repo = await ref.watch(reminderRepositoryProvider.future);
  return ReminderSchedulerService(repository: repo);
});

final ideaRepositoryProvider = FutureProvider<IdeaRepositoryImpl>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return IdeaRepositoryImpl(isar);
});

final noteRepositoryProvider = FutureProvider<NoteRepositoryImpl>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return NoteRepositoryImpl(isar);
});

// ── App state ────────────────────────────────────────────────────────────────

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingCompleteNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingCompleteNotifier(prefs);
});

final privacySetupCompleteProvider =
    StateNotifierProvider<PrivacySetupCompleteNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PrivacySetupCompleteNotifier(prefs);
});

/// Whether the user enabled app lock (fingerprint / PIN). Reactive for Settings.
final appLockEnabledProvider =
    StateNotifierProvider<AppLockEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppLockEnabledNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _load(SharedPreferences prefs) {
    return switch (prefs.getString(AppConstants.themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(
      AppConstants.themeModeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }
}

class OnboardingCompleteNotifier extends StateNotifier<bool> {
  OnboardingCompleteNotifier(this._prefs)
      : super(_prefs.getBool(AppConstants.onboardingCompleteKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> complete() async {
    await _prefs.setBool(AppConstants.onboardingCompleteKey, true);
    state = true;
  }
}

class PrivacySetupCompleteNotifier extends StateNotifier<bool> {
  PrivacySetupCompleteNotifier(this._prefs)
      : super(_prefs.getBool(AppConstants.privacySetupCompleteKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> complete() async {
    await _prefs.setBool(AppConstants.privacySetupCompleteKey, true);
    state = true;
  }
}

class AppLockEnabledNotifier extends StateNotifier<bool> {
  AppLockEnabledNotifier(this._prefs)
      : super(_prefs.getBool(AppConstants.appLockEnabledKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.appLockEnabledKey, enabled);
    state = enabled;
  }
}

final privacyLockProvider =
    StateNotifierProvider<PrivacyLockNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final privacySetupDone = ref.watch(privacySetupCompleteProvider);
  final enabled = prefs.getBool(AppConstants.appLockEnabledKey) ?? false;
  return PrivacyLockNotifier(
    prefs,
    lockOnStart: privacySetupDone && enabled,
  );
});

class PrivacyLockNotifier extends StateNotifier<bool> {
  PrivacyLockNotifier(this._prefs, {required bool lockOnStart})
      : super(false) {
    if (lockOnStart) state = true;
  }

  final SharedPreferences _prefs;

  DateTime? _backgroundedAt;

  /// While true, resume must not re-lock (e.g. mid biometric / PIN sheet).
  bool _authInProgress = false;

  bool get isAppLockEnabled =>
      _prefs.getBool(AppConstants.appLockEnabledKey) ?? false;

  /// Call when the app truly goes to background (paused), not for brief overlays.
  void markBackgrounded() {
    if (!isAppLockEnabled || state || _authInProgress) return;
    _backgroundedAt = DateTime.now();
  }

  /// On resume: lock only if backgrounded longer than the grace period.
  void evaluateLockOnResume() {
    if (!isAppLockEnabled || state || _authInProgress) {
      _backgroundedAt = null;
      return;
    }

    final leftAt = _backgroundedAt;
    _backgroundedAt = null;
    if (leftAt == null) return;

    final elapsed = DateTime.now().difference(leftAt);
    if (elapsed.inSeconds >= AppConstants.appLockGraceSeconds) {
      state = true;
    }
  }

  void lock() {
    if (isAppLockEnabled && !_authInProgress) state = true;
  }

  void unlock() {
    state = false;
    _backgroundedAt = null;
  }

  void setAuthInProgress(bool inProgress) {
    _authInProgress = inProgress;
  }
}
