import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'icon_toggle.dart';
import 'sky_icon.dart';

/// Closed-eye private toggle (matches task create form).
class PrivateIconToggle extends StatelessWidget {
  const PrivateIconToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconToggle(
      active: value,
      tooltip: value ? 'Make public' : 'Make private',
      onTap: enabled ? () => onChanged(!value) : null,
      child: SkyIcon(
        SkyIcons.private,
        color: value ? AppColors.primary : AppColors.primaryText,
        size: 22,
      ),
    );
  }
}
