import 'package:flutter/material.dart';

import 'sky_icon.dart';

/// Title row with circular close for create/edit bottom sheets.
class FormSheetHeader extends StatelessWidget {
  const FormSheetHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: SkyIcon(
                  SkyIcons.close,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
