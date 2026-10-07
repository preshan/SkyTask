import 'dart:math' as math;

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
    barrierColor: Colors.black.withValues(alpha: 0.45),
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
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // Anchor above the bottom Create nav item (center slot).
    final navHeight = 64.0 + media.padding.bottom;
    final center = Offset(
      media.size.width / 2,
      media.size.height - navHeight + 20,
    );
    const radius = 118.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _close(),
            ),
          ),
          AnimatedBuilder(
            animation: _expand,
            builder: (context, _) {
              final t = _expand.value.clamp(0.0, 1.0);
              final children = <Widget>[];

              for (var i = 0; i < _actions.length; i++) {
                // Arc from ~200° to ~340° (above center, left → right).
                final angle = (math.pi * 1.12) +
                    (math.pi * 0.76) * (i / (_actions.length - 1));
                final dx = math.cos(angle) * radius * t;
                final dy = math.sin(angle) * radius * t;
                final action = _actions[i];

                children.add(
                  Positioned(
                    left: center.dx + dx - 28,
                    top: center.dy + dy - 36,
                    child: Opacity(
                      opacity: t,
                      child: _RadialActionButton(
                        icon: action.$2,
                        label: action.$3,
                        color: brand,
                        surface: surface,
                        onTap: () => _close(action.$1),
                      ),
                    ),
                  ),
                );
              }

              children.add(
                Positioned(
                  left: center.dx - 28,
                  top: center.dy - 28,
                  child: GestureDetector(
                    onTap: () => _close(),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: t * (math.pi / 4),
                          child: SkyIcon(
                            SkyIcons.close,
                            color: onSurface,
                            size: 26,
                            strokeWidth: 2,
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
                  top: center.dy + 40,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: t,
                      child: Text(
                        'Create',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
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
        ],
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
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: SkyIcon(icon, color: color, size: 24),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
