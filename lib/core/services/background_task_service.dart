import 'package:workmanager/workmanager.dart';

import '../constants/app_constants.dart';
import 'alarm_service.dart';

/// Background work for timezone changes and periodic reminder health checks.
class BackgroundTaskService {
  BackgroundTaskService._();
  static final BackgroundTaskService instance = BackgroundTaskService._();

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
  }

  Future<void> registerTimezoneChangeHandler() async {
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
