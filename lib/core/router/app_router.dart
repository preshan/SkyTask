import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/providers.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/ideas/presentation/screens/ideas_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/privacy/presentation/screens/privacy_setup_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../../shared/widgets/app_shell.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const privacySetup = '/privacy-setup';
  static const home = '/home';
  static const tasks = '/tasks';
  static const calendar = '/calendar';
  static const ideas = '/ideas';
  static const settings = '/settings';

  static String tasksCreatedToday() => '$tasks?createdToday=1';
  static String ideasCreatedToday() => '$ideas?tab=ideas&createdToday=1';
  static String notesCreatedToday() => '$ideas?tab=notes&createdToday=1';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingDone = ref.watch(onboardingCompleteProvider);
  final privacySetupDone = ref.watch(privacySetupCompleteProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == AppRoutes.splash) return null;

      if (!onboardingDone) {
        if (location != AppRoutes.onboarding) return AppRoutes.onboarding;
        return null;
      }

      if (!privacySetupDone) {
        if (location != AppRoutes.privacySetup) return AppRoutes.privacySetup;
        return null;
      }

      if (location == AppRoutes.onboarding ||
          location == AppRoutes.privacySetup) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacySetup,
        builder: (_, __) => const PrivacySetupScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            pageBuilder: (_, state) => NoTransitionPage(
              child: TasksScreen(
                createdToday:
                    state.uri.queryParameters['createdToday'] == '1',
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: CalendarScreen()),
          ),
          GoRoute(
            path: AppRoutes.ideas,
            pageBuilder: (_, state) {
              final tab = state.uri.queryParameters['tab'];
              final initialTab = tab == 'notes' ? 1 : 0;
              return NoTransitionPage(
                child: IdeasScreen(
                  initialTab: initialTab,
                  createdToday:
                      state.uri.queryParameters['createdToday'] == '1',
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
