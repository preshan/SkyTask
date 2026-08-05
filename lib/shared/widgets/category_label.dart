import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/task_categories.dart';

/// Compact colored category pill for list tiles and subtitles.
class CategoryLabel extends ConsumerWidget {
  const CategoryLabel(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(customTaskCategoriesProvider);
    final overrides = ref.watch(defaultCategoryColorsProvider);
    final colorValue = TaskCategories.colorFor(
      name,
      custom: custom,
      defaultOverrides: overrides,
    );
    final fill = Color(colorValue);
    final onFill = _onPastel(fill);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: fill.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        TaskCategories.normalize(name),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: onFill,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.1,
            ),
      ),
    );
  }
}

Color _onPastel(Color fill) {
  final luminance = fill.computeLuminance();
  return luminance > 0.55 ? const Color(0xFF3D3D3D) : Colors.white;
}
