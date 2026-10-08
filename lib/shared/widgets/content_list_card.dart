import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'list_tile_trailing.dart';
import 'private_content_gate.dart';
import 'sky_icon.dart';

/// Solid list row matching the Ideas card layout: title, category, body, trailing.
class ContentListCard extends StatelessWidget {
  const ContentListCard({
    super.key,
    required this.title,
    required this.isPrivate,
    this.onTap,
    this.onLongPress,
    this.leading,
    this.categorySlot,
    this.body,
    this.trailing = const [],
    this.titleStyle,
    this.dimmed = false,
    this.compact = false,
    this.showChevron = true,
  });

  final String title;
  final bool isPrivate;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? leading;
  /// Usually a [CategoryLabel], or a row with label + tags.
  final Widget? categorySlot;
  final String? body;
  final List<Widget> trailing;
  final TextStyle? titleStyle;
  final bool dimmed;
  final bool compact;
  final bool showChevron;

  static Color surfaceColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.94)
        : AppColors.glassFillElevatedFor(brightness);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTitleStyle = titleStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.15,
              fontWeight: FontWeight.w600,
            );
    final subtitleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        );
    final hasBody = body != null && body!.trim().isNotEmpty;
    final hasSubtitle = categorySlot != null || hasBody;

    final card = Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 8),
      color: surfaceColor(context),
      child: PrivateContentGate(
        isPrivate: isPrivate,
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          minVerticalPadding: 4,
          onTap: onTap,
          onLongPress: onLongPress,
          leading: leading,
          title: Text(
            title,
            style: resolvedTitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: hasSubtitle
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categorySlot != null) categorySlot!,
                      if (hasBody) ...[
                        if (categorySlot != null) const SizedBox(height: 2),
                        Text(
                          body!,
                          style: subtitleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                )
              : null,
          trailing: ListTileTrailing(
            children: [
              ...trailing,
              if (showChevron && onTap != null)
                const SkyIcon(SkyIcons.chevronRight, size: 18),
            ],
          ),
        ),
      ),
    );

    if (!dimmed) return card;

    return AnimatedOpacity(
      opacity: 0.6,
      duration: const Duration(milliseconds: 300),
      child: card,
    );
  }
}
