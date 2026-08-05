import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'sky_icon.dart';

/// Compact brand "+" for listing AppBars — opens the screen's create sheet.
class ListAddButton extends StatelessWidget {
  const ListAddButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Add',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    final onBrand = Theme.of(context).colorScheme.onPrimary;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: brand,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: SkyIcon(
            SkyIcons.add,
            color: onBrand,
            size: 16,
            strokeWidth: 2.2,
          ),
        ),
      ),
    );
  }
}
