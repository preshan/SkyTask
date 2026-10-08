import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Pill-shaped form footer button (Save / Complete / Archive / Delete).
class FormActionButton extends StatelessWidget {
  const FormActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FormActionVariant.filled,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FormActionVariant variant;
  final bool busy;

  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(28),
  );

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    return switch (variant) {
      FormActionVariant.filled => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            shape: _shape,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: child,
        ),
      FormActionVariant.outlined => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: _shape,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: AppColors.brand(context)),
            foregroundColor: AppColors.brand(context),
          ),
          child: child,
        ),
      FormActionVariant.neutral => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: _shape,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
            ),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: child,
        ),
      FormActionVariant.danger => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: _shape,
            padding: const EdgeInsets.symmetric(vertical: 14),
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          child: child,
        ),
    };
  }
}

enum FormActionVariant { filled, outlined, neutral, danger }
