import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/app_info.dart';
import 'core/di/providers.dart';
import 'core/services/alarm_service.dart';
import 'core/services/background_task_service.dart';
import 'core/services/isar_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/private_crypto_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final packageInfo = await PackageInfo.fromPlatform();
  AppInfo.applyPackageInfo(
    versionName: packageInfo.version,
    build: packageInfo.buildNumber,
  );

  final prefs = await SharedPreferences.getInstance();
  await PrivateCryptoService.instance.init();
  await IsarService.instance.db;
  await NotificationService.instance.initialize();
  await AlarmService.instance.initialize();
  // Do not call scheduleBootReschedule() here — that re-posted overdue
  // notifications on every app open. Reboot is covered by AlarmManager /
  // FLN boot receivers; periodic WorkManager does future-only health checks.
  await BackgroundTaskService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SkyTaskApp(),
    ),
  );
}
