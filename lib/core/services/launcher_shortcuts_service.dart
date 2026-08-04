import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../shared/create/create_kind.dart';

/// Registers home-screen shortcuts (Android App Shortcuts / iOS Quick Actions).
///
/// Android also declares the same ids in `res/xml/shortcuts.xml` so they appear
/// before the first Flutter frame. Dynamic items below refresh icons/titles;
/// tap handling for cold starts uses the `skytask://app/create/...` deep link,
/// while warm starts also set [pendingCreateKindProvider].
abstract final class LauncherShortcutsService {
  static const _quickActions = QuickActions();
  static bool _installed = false;

  static Future<void> install(ProviderContainer container) async {
    if (_installed) return;
    _installed = true;

    try {
      await _quickActions.initialize((type) {
        final kind = createKindFromShortcutType(type);
        if (kind == null) return;
        container.read(pendingCreateKindProvider.notifier).state = kind;
      });

      await _quickActions.setShortcutItems(const [
        ShortcutItem(
          type: 'create_task',
          localizedTitle: 'New Task',
          localizedSubtitle: 'Create a task',
          icon: 'ic_shortcut_task',
        ),
        ShortcutItem(
          type: 'create_reminder',
          localizedTitle: 'New Reminder',
          localizedSubtitle: 'Set a reminder',
          icon: 'ic_shortcut_reminder',
        ),
        ShortcutItem(
          type: 'create_idea',
          localizedTitle: 'New Idea',
          localizedSubtitle: 'Capture an idea',
          icon: 'ic_shortcut_idea',
        ),
      ]);
    } catch (e, st) {
      debugPrint('LauncherShortcutsService: $e\n$st');
      _installed = false;
    }
  }
}
