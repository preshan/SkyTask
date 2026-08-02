import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../features/ideas/presentation/widgets/idea_form_sheet.dart';
import '../../features/notes/presentation/widgets/note_form_sheet.dart';
import '../../features/reminders/presentation/widgets/reminder_form_sheet.dart';
import '../../features/tasks/presentation/widgets/task_form_sheet.dart';
import 'sky_icon.dart';

/// Bottom nav: Home · Tasks · Create · Calendar · Ideas
/// Create sits in-line with the other icons (not a floating FAB).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _Tab(SkyIcons.home, SkyIcons.homeFilled, 'Home', AppRoutes.home),
    _Tab(SkyIcons.tasks, SkyIcons.tasksFilled, 'Tasks', AppRoutes.tasks),
    _Tab(SkyIcons.calendar, SkyIcons.calendarFilled, 'Calendar',
        AppRoutes.calendar),
    _Tab(SkyIcons.ideas, SkyIcons.ideasFilled, 'Ideas', AppRoutes.ideas),
  ];

  int? _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.settings)) return null;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Material(
        color: AppColors.card,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    tab: _tabs[0],
                    selected: selectedIndex == 0,
                    onTap: () => context.go(_tabs[0].route),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    tab: _tabs[1],
                    selected: selectedIndex == 1,
                    onTap: () => context.go(_tabs[1].route),
                  ),
                ),
                Expanded(
                  child: _CreateNavItem(
                    onTap: () => _showCreateMenu(context, ref),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    tab: _tabs[2],
                    selected: selectedIndex == 2,
                    onTap: () => context.go(_tabs[2].route),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    tab: _tabs[3],
                    selected: selectedIndex == 3,
                    onTap: () => context.go(_tabs[3].route),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateMenu(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _CreateOption(
                  icon: SkyIcons.task,
                  label: 'New Task',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await showTaskFormSheet(context, ref);
                  },
                ),
                _CreateOption(
                  icon: SkyIcons.alarm,
                  label: 'New Reminder',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await showReminderFormSheet(context, ref);
                  },
                ),
                _CreateOption(
                  icon: SkyIcons.lightbulb,
                  label: 'New Idea',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await showIdeaFormSheet(context, ref);
                  },
                ),
                _CreateOption(
                  icon: SkyIcons.note,
                  label: 'New Note',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await showNoteFormSheet(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.primaryText;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkyIcon(
            selected ? tab.selectedIcon : tab.icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateNavItem extends StatelessWidget {
  const _CreateNavItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: SkyIcon(
                SkyIcons.add,
                color: Colors.white,
                size: 22,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Create',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SkyIcon(icon, color: AppColors.primary, size: 22),
        ),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}

class _Tab {
  const _Tab(this.icon, this.selectedIcon, this.label, this.route);
  final List<List<dynamic>> icon;
  final List<List<dynamic>> selectedIcon;
  final String label;
  final String route;
}
