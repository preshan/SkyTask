import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import 'quick_action_fab.dart';

/// Android-first bottom navigation: Home, Tasks, Calendar, Ideas, Settings.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _Tab(Icons.home_outlined, Icons.home_rounded, 'Home', AppRoutes.home),
    _Tab(Icons.task_alt_outlined, Icons.task_alt, 'Tasks', AppRoutes.tasks),
    _Tab(Icons.calendar_month_outlined, Icons.calendar_month, 'Calendar',
        AppRoutes.calendar),
    _Tab(Icons.lightbulb_outline, Icons.lightbulb, 'Ideas', AppRoutes.ideas),
    _Tab(Icons.settings_outlined, Icons.settings, 'Settings', AppRoutes.settings),
  ];

  int _indexForLocation(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      extendBody: true,
      floatingActionButton: const QuickActionFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: AppColors.card,
        onDestinationSelected: (index) => context.go(_tabs[index].route),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.icon, this.selectedIcon, this.label, this.route);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
}
