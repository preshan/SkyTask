import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../create/create_kind.dart';
import 'frosted_surface.dart';
import 'sky_atmosphere_background.dart';
import 'sky_icon.dart';

/// Bottom nav: Home · Tasks · Create · Calendar · Ideas
/// Create sits in-line with the other icons (not a floating FAB).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _tabs = [
    _Tab(SkyIcons.home, SkyIcons.homeFilled, 'Home', AppRoutes.home),
    _Tab(SkyIcons.tasks, SkyIcons.tasksFilled, 'Tasks', AppRoutes.tasks),
    _Tab(SkyIcons.calendar, SkyIcons.calendarFilled, 'Calendar',
        AppRoutes.calendar),
    _Tab(SkyIcons.ideas, SkyIcons.ideasFilled, 'Ideas', AppRoutes.ideas),
  ];

  bool _openingCreate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeCreateRequest());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Launcher deep link: /home?create=task|reminder|idea
    if (GoRouterState.of(context).uri.queryParameters['create'] != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _consumeCreateRequest());
    }
  }

  int? _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.settings)) return null;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  Future<void> _consumeCreateRequest() async {
    if (!mounted || _openingCreate) return;

    final fromQuery = createKindFromQuery(
      GoRouterState.of(context).uri.queryParameters['create'],
    );
    final fromShortcut = ref.read(pendingCreateKindProvider);
    final kind = fromQuery ?? fromShortcut;
    if (kind == null) return;

    _openingCreate = true;
    ref.read(pendingCreateKindProvider.notifier).state = null;

    final path = GoRouterState.of(context).uri.path;
    if (GoRouterState.of(context).uri.queryParameters.containsKey('create')) {
      context.go(path);
    }

    await openCreateSheet(context, ref, kind);
    if (mounted) _openingCreate = false;
  }

  Future<void> _showCreateMenu() async {
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
                    await openCreateSheet(context, ref, CreateKind.task);
                  },
                ),
                _CreateOption(
                  icon: SkyIcons.alarm,
                  label: 'New Reminder',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await openCreateSheet(context, ref, CreateKind.reminder);
                  },
                ),
                _CreateOption(
                  icon: SkyIcons.lightbulb,
                  label: 'New Idea',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await openCreateSheet(context, ref, CreateKind.idea);
                  },
                ),
                _CreateOption(
                  icon: SkyIcons.note,
                  label: 'New Note',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await openCreateSheet(context, ref, CreateKind.note);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForLocation(location);

    ref.listen<CreateKind?>(pendingCreateKindProvider, (prev, next) {
      if (next != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _consumeCreateRequest());
      }
    });

    return SkyAtmosphereBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: widget.child,
        bottomNavigationBar: FrostedSurface(
          borderRadius: 0,
          elevated: true,
          borderWidth: 0,
          child: Material(
            color: Colors.transparent,
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
                      child: _CreateNavItem(onTap: _showCreateMenu),
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
        ),
      ),
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
    final scheme = Theme.of(context).colorScheme;
    final color =
        selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.55);

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
    final brand = AppColors.brand(context);
    final onBrand = Theme.of(context).colorScheme.onPrimary;

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
              color: brand,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: SkyIcon(
                SkyIcons.add,
                color: onBrand,
                size: 22,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Create',
            style: TextStyle(
              fontSize: 12,
              color: brand,
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
    final brand = AppColors.brand(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: brand.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SkyIcon(icon, color: brand, size: 22),
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
