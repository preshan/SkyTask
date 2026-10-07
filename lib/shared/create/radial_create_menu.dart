import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../widgets/sky_icon.dart';
import 'create_kind.dart';

/// Full-screen radial / speed-dial create picker anchored above the nav Create button.
Future<CreateKind?> showRadialCreateMenu(BuildContext context) {
  return showGeneralDialog<CreateKind>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss create menu',
    // Scrim is drawn inside the page so it fades with the menu.
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim, secondary) {
      return const _RadialCreateMenu();
    },
    transitionBuilder: (ctx, anim, secondary, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

class _RadialCreateMenu extends StatefulWidget {
  const _RadialCreateMenu();

  @override
  State<_RadialCreateMenu> createState() => _RadialCreateMenuState();
}

class _RadialCreateMenuState extends State<_RadialCreateMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expand;

  static const _actions = <(CreateKind, List<List<dynamic>>, String)>[
    (CreateKind.task, SkyIcons.task, 'Task'),
    (CreateKind.reminder, SkyIcons.alarm, 'Reminder'),
    (CreateKind.idea, SkyIcons.lightbulb, 'Idea'),
    (CreateKind.note, SkyIcons.note, 'Note'),
    (CreateKind.link, SkyIcons.link, 'Link'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _expand = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close([CreateKind? kind]) async {
    await _controller.reverse();
    if (mounted) Navigator.pop(context, kind);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final brand = AppColors.brand(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final chipFg = brand;
    final closeBg = isDark ? const Color(0xFF334155) : Colors.white;

    // Anchor above the bottom Create nav item (center slot).
    final navHeight = 64.0 + media.padding.bottom;
    final center = Offset(
      media.size.width / 2,
      media.size.height - navHeight + 8,
    );
    const radius = 128.0;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _expand,
        builder: (context, _) {
          final t = _expand.value.clamp(0.0, 1.0);
          final children = <Widget>[
            // Dim + blur the page behind so shortcuts no longer compete.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _close(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 6 * t,
                    sigmaY: 6 * t,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55 * t),
                  ),
                ),
              ),
            ),
          ];

          for (var i = 0; i < _actions.length; i++) {
            // Arc from ~200° to ~340° (above center, left → right).
            final angle = (math.pi * 1.12) +
                (math.pi * 0.76) * (i / (_actions.length - 1));
            final dx = math.cos(angle) * radius * t;
            final dy = math.sin(angle) * radius * t;
            final action = _actions[i];

            children.add(
              Positioned(
                left: center.dx + dx - 30,
                top: center.dy + dy - 40,
                child: Opacity(
                  opacity: t,
                  child: _RadialActionButton(
                    icon: action.$2,
                    label: action.$3,
                    color: chipFg,
                    surface: chipBg,
                    onTap: () => _close(action.$1),
                  ),
                ),
              ),
            );
          }

          children.add(
            Positioned(
              left: center.dx - 30,
              top: center.dy - 30,
              child: GestureDetector(
                onTap: () => _close(),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: brand,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: closeBg, width: 2),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: t * (math.pi / 4),
                      child: SkyIcon(
                        SkyIcons.close,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 26,
                        strokeWidth: 2.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          children.add(
            Positioned(
              left: 0,
              right: 0,
              top: center.dy + 42,
              child: IgnorePointer(
                child: Opacity(
                  opacity: t,
                  child: Text(
                    'Tap to close',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          );

          return Stack(children: children);
        },
      ),
    );
  }
}

class _RadialActionButton extends StatelessWidget {
  const _RadialActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: SkyIcon(icon, color: color, size: 24),
              ),
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
