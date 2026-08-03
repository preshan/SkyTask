import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Full-bleed day sky or night sky behind the app shell.
class SkyAtmosphereBackground extends StatelessWidget {
  const SkyAtmosphereBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.atmosphereGradientFor(brightness),
          ),
        ),
        if (isDark)
          const Positioned.fill(
            child: CustomPaint(painter: _StarFieldPainter()),
          ),
        if (child != null) child!,
      ],
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(42);

    for (var i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.72;
      final r = 0.6 + rng.nextDouble() * 1.4;
      paint.color = Colors.white.withValues(alpha: 0.25 + rng.nextDouble() * 0.55);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
