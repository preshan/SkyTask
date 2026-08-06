import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/task_categories.dart';
import 'category_chip_selector.dart';

/// Horizontal All + category chips matching the Tasks list filter row.
class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.usedLabels,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  /// `null` means All.
  final String? selected;
  final Iterable<String> usedLabels;
  final ValueChanged<String?> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(customTaskCategoriesProvider);
    final overrides = ref.watch(defaultCategoryColorsProvider);
    final categories = TaskCategories.ordered(
      custom: custom,
      usedLabels: usedLabels,
      defaultOverrides: overrides,
    );

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          _CategoryFilterChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          ...categories.map(
            (category) => _CategoryFilterChip(
              label: category.name,
              color: category.color,
              selected:
                  selected?.toLowerCase() == category.name.toLowerCase(),
              onTap: () => onChanged(category.name),
              onLongPress: () => showCategoryManageSheet(
                context: context,
                ref: ref,
                category: category,
                currentSelection: selected ?? '',
                onDeletedOrRenamed: (next) {
                  if (selected?.toLowerCase() ==
                      category.name.toLowerCase()) {
                    onChanged(next);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? color;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final fill = color != null ? Color(color!) : null;
    final onFill = fill != null && fill.computeLuminance() > 0.55
        ? const Color(0xFF3D3D3D)
        : (fill != null ? Colors.white : null);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: FilterChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onTap(),
          selectedColor:
              fill ?? AppColors.brand(context).withValues(alpha: 0.25),
          backgroundColor: fill?.withValues(alpha: 0.45) ??
              Theme.of(context).colorScheme.surface,
          side: BorderSide(
            color: selected
                ? (fill ?? AppColors.brand(context))
                : (fill?.withValues(alpha: 0.7) ??
                    AppColors.brand(context).withValues(alpha: 0.25)),
          ),
          labelStyle: TextStyle(
            color: selected
                ? (onFill ?? Theme.of(context).colorScheme.onSurface)
                : (onFill?.withValues(alpha: 0.85) ??
                    Theme.of(context).colorScheme.onSurface),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
