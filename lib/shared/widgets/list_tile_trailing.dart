import 'package:flutter/material.dart';

/// Trailing actions for content [ListTile]s — keeps icons in a compact row.
/// Prefer leaving [ListTile.isThreeLine] false so Material vertically centers this.
class ListTileTrailing extends StatelessWidget {
  const ListTileTrailing({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
