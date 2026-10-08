import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Labeled grey tile used for Due date / Time / Pin / Hide rows.
class FormQuickActionTile extends StatelessWidget {
  const FormQuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
    this.onLongPress,
    this.tooltip,
  });

  final Widget icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = AppColors.brand(context);
    final tile = Material(
      color: active
          ? brand.withValues(alpha: 0.14)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active
                          ? brand
                          : scheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip == null) return tile;
    return Tooltip(message: tooltip!, child: tile);
  }
}
