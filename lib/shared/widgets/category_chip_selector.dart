import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/task_categories.dart';
import 'sky_icon.dart';

/// Shared Work / Personal / custom category chips used by all content forms.
class CategoryChipSelector extends ConsumerWidget {
  const CategoryChipSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => const _NewCategoryDialog(),
    );
    if (name == null) return;
    final normalized = TaskCategories.normalize(name);
    if (normalized.isEmpty) return;
    await ref.read(customTaskCategoriesProvider.notifier).add(normalized);
    onChanged(normalized);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(customTaskCategoriesProvider);
    final used =
        ref.watch(categoryUsageLabelsProvider).valueOrNull ?? const <String>[];
    final categories =
        TaskCategories.ordered(custom: custom, usedLabels: used);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Category', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == categories.length) {
                return FilterChip(
                  avatar: SkyIcon(
                    SkyIcons.add,
                    size: 16,
                    color: AppColors.brand(context),
                  ),
                  label: const Text('Add'),
                  selected: false,
                  showCheckmark: false,
                  onSelected: enabled ? (_) => _addCategory(context, ref) : null,
                  side: BorderSide(
                    color: AppColors.brand(context).withValues(alpha: 0.35),
                  ),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }
              final category = categories[index];
              final selected =
                  value.toLowerCase() == category.toLowerCase();
              return FilterChip(
                label: Text(category),
                selected: selected,
                showCheckmark: false,
                onSelected: enabled ? (_) => onChanged(category) : null,
                selectedColor:
                    AppColors.brand(context).withValues(alpha: 0.25),
                side: BorderSide(
                  color: selected
                      ? AppColors.brand(context)
                      : AppColors.brand(context).withValues(alpha: 0.25),
                ),
                labelStyle: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'e.g. Health, Study',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
