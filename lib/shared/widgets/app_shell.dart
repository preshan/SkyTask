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
        final divider = Theme.of(ctx).dividerColor.withValues(alpha: 0.55);
        final options = [
          (
            icon: SkyIcons.task,
            label: 'Task',
            kind: CreateKind.task,
          ),
          (
            icon: SkyIcons.alarm,
            label: 'Reminder',
            kind: CreateKind.reminder,
          ),
          (
            icon: SkyIcons.lightbulb,
            label: 'Idea',
            kind: CreateKind.idea,
          ),
          (
            icon: SkyIcons.note,
            label: 'Note',
            kind: CreateKind.note,
          ),
        ];

        Future<void> open(CreateKind kind) async {
          Navigator.pop(ctx);
          await openCreateSheet(context, ref, kind);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 236,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _CreateGridCell(
                                    icon: options[0].icon,
                                    label: options[0].label,
                                    onTap: () => open(options[0].kind),
                                  ),
                                ),
                                Expanded(
                                  child: _CreateGridCell(
                                    icon: options[1].icon,
                                    label: options[1].label,
                                    onTap: () => open(options[1].kind),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _CreateGridCell(
                                    icon: options[2].icon,
                                    label: options[2].label,
                                    onTap: () => open(options[2].kind),
                                  ),
                                ),
                                Expanded(
                                  child: _CreateGridCell(
                                    icon: options[3].icon,
                                    label: options[3].label,
                                    onTap: () => open(options[3].kind),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CreateGridCrossPainter(color: divider),
                          ),
                        ),
                      ),
                    ],
                  ),
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

class _CreateGridCell extends StatelessWidget {
  const _CreateGridCell({
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
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkyIcon(icon, color: brand, size: 36),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateGridCrossPainter extends CustomPainter {
  _CreateGridCrossPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final midX = size.width / 2;
    final midY = size.height / 2;
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), paint);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(covariant _CreateGridCrossPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Tab {
  const _Tab(this.icon, this.selectedIcon, this.label, this.route);
  final List<List<dynamic>> icon;
  final List<List<dynamic>> selectedIcon;
  final String label;
  final String route;
}
