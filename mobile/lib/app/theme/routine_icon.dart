import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom-crafted icon for the "Routines" feature in Bloom.
///
/// Visual concept:
/// - A continuous orbital ritual loop representing the daily cyclical flow of habits.
/// - Three sequential habit beads (nodes) along the orbit representing Step 1, Step 2, and Step 3.
/// - Clockwise flow dynamics.
/// - In the inactive state: Elegant 1.8px stroked contour with clean circular step nodes.
/// - In the active state: Vibrant filled milestone nodes, illuminated primary track,
///   and a delicate four-pointed Bloom star/sparkle at the core of the ritual.
class RoutineNavIcon extends StatelessWidget {
  const RoutineNavIcon({
    super.key,
    required this.isSelected,
    required this.color,
    this.size = 24.0,
  });

  /// Whether the navigation tab is currently selected.
  final bool isSelected;

  /// Foreground icon color (active or inactive token).
  final Color color;

  /// Width and height of the icon (defaults to 24px standard nav icon size).
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RoutineIconPainter(
          isSelected: isSelected,
          color: color,
        ),
      ),
    );
  }
}

class _RoutineIconPainter extends CustomPainter {
  const _RoutineIconPainter({
    required this.isSelected,
    required this.color,
  });

  final bool isSelected;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbitRadius = size.width * 0.34; // ~8.16px on 24x24

    // Track paint
    final trackPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.2 : 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw the continuous ritual arc (almost full loop with slight gap for flow direction)
    // Sweep ~310 degrees (5.41 radians) clockwise starting at -pi/2 + 0.35
    const startAngle = -math.pi / 2 + 0.35;
    const sweepAngle = math.pi * 1.76;

    final orbitRect = Rect.fromCircle(center: center, radius: orbitRadius);
    canvas.drawArc(orbitRect, startAngle, sweepAngle, false, trackPaint);

    // Three ritual nodes/beads representing the habit sequence:
    // Node 1: Top (12 o'clock / Start) -> angle: -pi / 2
    // Node 2: Bottom-right (~4 o'clock / Progress) -> angle: -pi / 2 + 2 * pi / 3 = pi / 6
    // Node 3: Bottom-left (~8 o'clock / Completion) -> angle: -pi / 2 + 4 * pi / 3 = 5 * pi / 6
    final nodeAngles = [
      -math.pi / 2,
      math.pi / 6,
      5 * math.pi / 6,
    ];

    final nodePaint = Paint()..color = color;

    for (int i = 0; i < nodeAngles.length; i++) {
      final angle = nodeAngles[i];
      final nodePos = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );

      if (isSelected) {
        // Active state: filled solid ritual beads
        nodePaint.style = PaintingStyle.fill;
        canvas.drawCircle(nodePos, 2.5, nodePaint);
      } else {
        // Inactive state: clean outlined beads with inner cutout
        nodePaint.style = PaintingStyle.fill;
        canvas.drawCircle(nodePos, 2.1, nodePaint);

        final innerHolePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.dstOut; // Erase center for transparent cutout
        canvas.drawCircle(nodePos, 1.0, innerHolePaint);
      }
    }

    // Directional flow arrow tip at the end of the arc (near node 1)
    final endAngle = startAngle + sweepAngle;
    final endPos = Offset(
      center.dx + orbitRadius * math.cos(endAngle),
      center.dy + orbitRadius * math.sin(endAngle),
    );

    // Tangent angle pointing clockwise along the circle: endAngle + pi / 2
    final tangent = endAngle + math.pi / 2;
    const arrowLength = 3.6;
    const arrowWingAngle = math.pi * 0.72;

    final arrowPath = Path()
      ..moveTo(
        endPos.dx + arrowLength * math.cos(tangent - arrowWingAngle),
        endPos.dy + arrowLength * math.sin(tangent - arrowWingAngle),
      )
      ..lineTo(endPos.dx, endPos.dy)
      ..lineTo(
        endPos.dx + arrowLength * math.cos(tangent + arrowWingAngle),
        endPos.dy + arrowLength * math.sin(tangent + arrowWingAngle),
      );

    canvas.drawPath(arrowPath, trackPaint);

    // Center accent:
    if (isSelected) {
      // Four-pointed radiant Bloom star / sparkle in the center
      final starPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final starPath = Path();
      const starRadius = 3.4;
      const innerIndent = 0.85;

      starPath.moveTo(center.dx, center.dy - starRadius);
      starPath.quadraticBezierTo(
        center.dx + innerIndent,
        center.dy - innerIndent,
        center.dx + starRadius,
        center.dy,
      );
      starPath.quadraticBezierTo(
        center.dx + innerIndent,
        center.dy + innerIndent,
        center.dx,
        center.dy + starRadius,
      );
      starPath.quadraticBezierTo(
        center.dx - innerIndent,
        center.dy + innerIndent,
        center.dx - starRadius,
        center.dy,
      );
      starPath.quadraticBezierTo(
        center.dx - innerIndent,
        center.dy - innerIndent,
        center.dx,
        center.dy - starRadius,
      );
      starPath.close();

      canvas.drawPath(starPath, starPaint);
    } else {
      // Inactive: tiny subtle core dot
      final corePaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 1.2, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutineIconPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected || oldDelegate.color != color;
  }
}
