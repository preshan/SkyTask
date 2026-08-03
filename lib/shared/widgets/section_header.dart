import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData? action;
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
              icon: Icon(action ?? Icons.arrow_forward, size: 18),
              label: Text(actionLabel ?? 'See all'),
            ),
        ],
      ),
    );
  }
}
