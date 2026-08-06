import 'dart:math' as math;
import 'dart:ui' as ui;

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
            child: CustomPaint(painter: _NightAtmospherePainter()),
          ),
        if (child != null) child!,
      ],
    );
  }
}

/// Soft night glow — no busy white star dots that fight the UI.
class _NightAtmospherePainter extends CustomPainter {
  const _NightAtmospherePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Deep indigo wash near the top.
    final topWash = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height * 0.45),
        [
          const Color(0xFF1E3A5F).withValues(alpha: 0.35),
          const Color(0xFF1E3A5F).withValues(alpha: 0.0),
        ],
      );
    canvas.drawRect(Offset.zero & size, topWash);

    // Soft nebula / aurora blobs (low contrast, no speckles).
    _paintGlow(
      canvas,
      center: Offset(size.width * 0.18, size.height * 0.12),
      radius: size.width * 0.42,
      color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
    );
    _paintGlow(
      canvas,
      center: Offset(size.width * 0.88, size.height * 0.22),
      radius: size.width * 0.38,
      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
    );
    _paintGlow(
      canvas,
      center: Offset(size.width * 0.55, size.height * 0.08),
      radius: size.width * 0.28,
      color: const Color(0xFF93C5FD).withValues(alpha: 0.06),
    );
    _paintGlow(
      canvas,
      center: Offset(size.width * 0.72, size.height * 0.55),
      radius: size.width * 0.35,
      color: const Color(0xFF1E40AF).withValues(alpha: 0.10),
    );

    // Soft moon glow (upper-right), not a hard white disc.
    final moonCenter = Offset(size.width * 0.82, size.height * 0.11);
    _paintGlow(
      canvas,
      center: moonCenter,
      radius: 56,
      color: const Color(0xFFE2E8F0).withValues(alpha: 0.10),
    );
    _paintGlow(
      canvas,
      center: moonCenter,
      radius: 22,
      color: const Color(0xFFF1F5F9).withValues(alpha: 0.18),
    );

    // A handful of very faint pinpricks only — barely visible.
    final starPaint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.4;
      final r = 0.4 + rng.nextDouble() * 0.5;
      starPaint.color =
          const Color(0xFFCBD5E1).withValues(alpha: 0.08 + rng.nextDouble() * 0.10);
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  void _paintGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [color, color.withValues(alpha: 0)],
      );
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
