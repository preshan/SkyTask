import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Compact icon button that highlights when [active].
class IconToggle extends StatelessWidget {
  const IconToggle({
    super.key,
    required this.active,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.tooltip,
  });

  final bool active;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: active
          ? AppColors.primary.withValues(alpha: 0.18)
          : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
