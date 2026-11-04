import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app_theme.dart';

/// Contador circular de caracteres estilo Twitter (máximo 280).
class ForumCharCounter extends StatelessWidget {
  const ForumCharCounter({
    super.key,
    required this.length,
    this.maxLength = 280,
    this.size = 22,
  });

  final int length;
  final int maxLength;
  final double size;

  @override
  Widget build(BuildContext context) {
    final remaining = maxLength - length;
    final progress = (length / maxLength).clamp(0.0, 1.0);
    final color = remaining < 0
        ? AppColors.error
        : remaining <= 20
        ? const Color(0xFFFBBF24)
        : AppColors.neoCyan;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(progress: progress, color: color),
          ),
          if (remaining <= 20)
            Text(
              '$remaining',
              style: TextStyle(
                color: color,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(2.0, size.width * 0.12);
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    final background = Paint()
      ..color = AppColors.neoBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, background);

    final foreground = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
