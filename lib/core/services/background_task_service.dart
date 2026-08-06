import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../constants/app_constants.dart';
import 'alarm_service.dart';

/// Background work for timezone changes and periodic reminder health checks.
class BackgroundTaskService {
  BackgroundTaskService._();
  static final BackgroundTaskService instance = BackgroundTaskService._();

  static const _tzOffsetPrefsKey = 'skytask_tz_offset_minutes';

  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);

    await Workmanager().registerPeriodicTask(
      AppConstants.reminderRescheduleTask,
      AppConstants.reminderRescheduleTask,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    await _maybeRescheduleForTimezoneChange();
  }

  /// Only queues a one-off when the device timezone offset actually changed.
  Future<void> _maybeRescheduleForTimezoneChange() async {
    final prefs = await SharedPreferences.getInstance();
    final offset = DateTime.now().timeZoneOffset.inMinutes;
    final previous = prefs.getInt(_tzOffsetPrefsKey);
    if (previous == offset) return;

    await prefs.setInt(_tzOffsetPrefsKey, offset);
    if (previous == null) return; // first launch — nothing to migrate

    await Workmanager().registerOneOffTask(
      AppConstants.timezoneChangeTask,
      AppConstants.timezoneChangeTask,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    switch (taskName) {
      case AppConstants.reminderRescheduleTask:
      case AppConstants.timezoneChangeTask:
        await AlarmService.instance.rescheduleAllReminders();
        return true;
      default:
        return false;
    }
  });
}
