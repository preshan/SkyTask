import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'sky_icon.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionIcon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final List<List<dynamic>>? actionIcon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.brand(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          if (onAction != null)
            TextButton.icon(
              onPressed: onAction,
              icon: SkyIcon(
                actionIcon ?? SkyIcons.arrowForward,
                size: 18,
              ),
              label: Text(actionLabel ?? 'See all'),
            ),
        ],
      ),
    );
  }
}
