import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/share_intent_service.dart';
import '../../features/quick_links/domain/shared_link_payload.dart';
import '../create/create_kind.dart';
import '../create/radial_create_menu.dart';
import 'sky_atmosphere_background.dart';
import 'sky_icon.dart';

/// Extra height of the Create bump above the bar top edge.
const kNavBumpHeight = 20.0;
const kNavBarBodyHeight = 64.0;

/// Bottom nav: Home · Tasks · Create · Calendar · Ideas
/// Create sits in a small bump above the bar center.
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
  bool _shareListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeCreateRequest();
      _consumeSharedLink();
      _startShareListening();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Launcher deep link: /home?create=task|reminder|idea|note|link
    if (GoRouterState.of(context).uri.queryParameters['create'] != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _consumeCreateRequest());
    }
  }

  void _startShareListening() {
    if (_shareListening) return;
    _shareListening = true;
    ShareIntentService.instance.startListening((payload) {
      if (!mounted) return;
      ref.read(pendingSharedLinkProvider.notifier).state = payload;
      _consumeSharedLink();
    });
  }

  int? _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.settings) ||
        location.startsWith(AppRoutes.aboutHelp) ||
        location.startsWith(AppRoutes.privacyPolicy) ||
        location.startsWith(AppRoutes.faq) ||
        location.startsWith(AppRoutes.dataSafety)) {
      return null;
    }
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

  Future<void> _consumeSharedLink() async {
    if (!mounted || _openingCreate) return;
    // Wait until app lock is cleared so the form is usable.
    if (ref.read(privacyLockProvider)) return;

    SharedLinkPayload? pending = ref.read(pendingSharedLinkProvider);
    pending ??= await ShareIntentService.instance.takeInitialSharedLink();
    if (pending == null || pending.rawText.isEmpty) return;

    _openingCreate = true;
    ref.read(pendingSharedLinkProvider.notifier).state = null;
    if (!mounted) {
      _openingCreate = false;
      return;
    }
    await openCreateSheet(
      context,
      ref,
      CreateKind.link,
      shared: pending,
    );
    if (mounted) _openingCreate = false;
  }

  Future<void> _showCreateMenu() async {
    final kind = await showRadialCreateMenu(context);
    if (kind == null || !mounted) return;
    await openCreateSheet(context, ref, kind);
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
    ref.listen<SharedLinkPayload?>(pendingSharedLinkProvider, (prev, next) {
      if (next != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _consumeSharedLink());
      }
    });
    ref.listen<bool>(privacyLockProvider, (prev, next) {
      if (prev == true && next == false) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _consumeSharedLink());
      }
    });

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navTotalHeight = kNavBumpHeight + kNavBarBodyHeight + bottomInset;
    final brightness = Theme.of(context).brightness;
    final fill = AppColors.glassFillElevatedFor(brightness);
    final border = AppColors.glassBorderFor(brightness);

    return SkyAtmosphereBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: widget.child,
        bottomNavigationBar: SizedBox(
          height: navTotalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipPath(
                  clipper: _NavBumpClipper(
                    bumpHeight: kNavBumpHeight,
                    cornerRadius: 18,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: CustomPaint(
                      painter: _NavBumpBorderPainter(
                        bumpHeight: kNavBumpHeight,
                        cornerRadius: 18,
                        fill: fill,
                        border: border,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: kNavBarBodyHeight + bottomInset,
                child: Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: kNavBarBodyHeight,
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
                          const Expanded(child: SizedBox.shrink()),
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
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset + 6,
                child: Center(
                  child: _CreateNavItem(onTap: _showCreateMenu),
                ),
              ),
            ],
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
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: brand.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: SkyIcon(
                SkyIcons.add,
                color: onBrand,
                size: 24,
                strokeWidth: 2.2,
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

/// Top edge rises in a soft bump around the Create button.
class _NavBumpClipper extends CustomClipper<Path> {
  const _NavBumpClipper({
    required this.bumpHeight,
    required this.cornerRadius,
  });

  final double bumpHeight;
  final double cornerRadius;

  @override
  Path getClip(Size size) => _navBumpPath(size, bumpHeight, cornerRadius);

  @override
  bool shouldReclip(covariant _NavBumpClipper oldClipper) =>
      oldClipper.bumpHeight != bumpHeight ||
      oldClipper.cornerRadius != cornerRadius;
}

class _NavBumpBorderPainter extends CustomPainter {
  const _NavBumpBorderPainter({
    required this.bumpHeight,
    required this.cornerRadius,
    required this.fill,
    required this.border,
  });

  final double bumpHeight;
  final double cornerRadius;
  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _navBumpPath(size, bumpHeight, cornerRadius);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _NavBumpBorderPainter oldDelegate) =>
      oldDelegate.bumpHeight != bumpHeight ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.fill != fill ||
      oldDelegate.border != border;
}

Path _navBumpPath(Size size, double bumpHeight, double cornerRadius) {
  final w = size.width;
  final h = size.height;
  final top = bumpHeight;
  final cx = w / 2;
  // Width of the raised bump (wider than the Create circle).
  const bumpHalf = 42.0;
  final r = cornerRadius.clamp(0.0, 24.0);

  final path = Path()
    ..moveTo(r, top)
    ..lineTo(cx - bumpHalf - 10, top)
    // Smooth rise into the bump.
    ..cubicTo(
      cx - bumpHalf + 6,
      top,
      cx - bumpHalf + 10,
      2,
      cx - 22,
      2,
    )
    ..cubicTo(cx - 10, 0, cx + 10, 0, cx + 22, 2)
    ..cubicTo(
      cx + bumpHalf - 10,
      2,
      cx + bumpHalf - 6,
      top,
      cx + bumpHalf + 10,
      top,
    )
    ..lineTo(w - r, top)
    ..quadraticBezierTo(w, top, w, top + r)
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..lineTo(0, top + r)
    ..quadraticBezierTo(0, top, r, top)
    ..close();
  return path;
}

class _Tab {
  const _Tab(this.icon, this.selectedIcon, this.label, this.route);
  final List<List<dynamic>> icon;
  final List<List<dynamic>> selectedIcon;
  final String label;
  final String route;
}
