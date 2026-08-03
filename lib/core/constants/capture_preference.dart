import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_constants.dart';
import '../di/providers.dart';

/// Learns whether the user captures more with voice than by typing
/// into the description/content field — used to skip autofocus.
abstract final class CapturePreference {
  static bool preferVoiceOverTyping(SharedPreferences prefs) {
    final voice = prefs.getInt(AppConstants.captureVoiceSavesKey) ?? 0;
    final typed = prefs.getInt(AppConstants.captureTypedDescSavesKey) ?? 0;
    // Need a bit of signal before switching behavior.
    return voice >= 3 && voice > typed;
  }

  /// Call after a successful save.
  ///
  /// Counts voice when a memo is attached; counts typing when the
  /// description/content body is non-empty.
  static Future<void> recordSave(
    SharedPreferences prefs, {
    required bool hasVoice,
    required bool hasTypedBody,
  }) async {
    if (hasVoice) {
      final n = prefs.getInt(AppConstants.captureVoiceSavesKey) ?? 0;
      await prefs.setInt(AppConstants.captureVoiceSavesKey, n + 1);
    }
    if (hasTypedBody) {
      final n = prefs.getInt(AppConstants.captureTypedDescSavesKey) ?? 0;
      await prefs.setInt(AppConstants.captureTypedDescSavesKey, n + 1);
    }
  }
}

final preferVoiceCaptureProvider =
    StateNotifierProvider<PreferVoiceCaptureNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferVoiceCaptureNotifier(prefs);
});

class PreferVoiceCaptureNotifier extends StateNotifier<bool> {
  PreferVoiceCaptureNotifier(this._prefs)
      : super(CapturePreference.preferVoiceOverTyping(_prefs));

  final SharedPreferences _prefs;

  Future<void> recordSave({
    required bool hasVoice,
    required bool hasTypedBody,
  }) async {
    await CapturePreference.recordSave(
      _prefs,
      hasVoice: hasVoice,
      hasTypedBody: hasTypedBody,
    );
    state = CapturePreference.preferVoiceOverTyping(_prefs);
  }
}
