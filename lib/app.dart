import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/privacy/presentation/screens/lock_screen.dart';

class SkyTaskApp extends ConsumerStatefulWidget {
  const SkyTaskApp({super.key});

  @override
  ConsumerState<SkyTaskApp> createState() => _SkyTaskAppState();
}

class _SkyTaskAppState extends ConsumerState<SkyTaskApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(privacyLockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isLocked = ref.watch(privacyLockProvider);

    return MaterialApp.router(
      title: 'SkyTask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (isLocked) return const LockScreen();
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
