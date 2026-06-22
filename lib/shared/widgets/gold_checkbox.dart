import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';

/// Premium gold circular checkbox with Nike-style tick animation.
class GoldCheckbox extends StatefulWidget {
  const GoldCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 28,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  State<GoldCheckbox> createState() => _GoldCheckboxState();
}

class _GoldCheckboxState extends State<GoldCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _checkProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _checkProgress = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    if (widget.value) _controller.value = 1;
  }

  @override
  void didUpdateWidget(GoldCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value && !oldWidget.value) {
      _controller.forward(from: 0);
    } else if (!widget.value && oldWidget.value) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.value ? AppColors.goldAccent : Colors.white,
                border: Border.all(
                  color: widget.value
                      ? AppColors.completedGold
                      : AppColors.goldAccent,
                  width: 2,
                ),
                boxShadow: widget.value
                    ? [
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: CustomPaint(
                painter: _TickPainter(progress: _checkProgress.value),
              ),
            ),
          );
        },
      ),
    ).animate(target: widget.value ? 1 : 0).fade(duration: 200.ms);
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.75, size.height * 0.32);

    final metrics = path.computeMetrics().first;
    final extractPath = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}
