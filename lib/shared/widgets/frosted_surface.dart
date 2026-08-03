import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Frosted glass panel — blur + translucent fill over the sky background.
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.elevated = false,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool elevated;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fill = elevated
        ? AppColors.glassFillElevatedFor(brightness)
        : AppColors.glassFillFor(brightness);
    final border = borderColor ?? AppColors.glassBorderFor(brightness);
    final radius = BorderRadius.circular(borderRadius);

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: borderWidth > 0
                ? Border.all(color: border, width: borderWidth)
                : null,
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return content;
  }
}
