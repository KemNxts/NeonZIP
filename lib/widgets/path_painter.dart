import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/grid_pos.dart';
import '../models/player_path.dart';

/// Converts a grid cell coordinate to its pixel centre.
Offset gridToPixel(GridPos pos, double cellSize) {
  return Offset(pos.x * cellSize + cellSize / 2, pos.y * cellSize + cellSize / 2);
}

/// Custom painter that draws the player path with continuous rounded corners
/// and a dynamic finger-tracking leader segment.
class PathPainter extends CustomPainter {
  final PlayerPath playerPath;
  final double cellSize;
  final Color pathStart;
  final Color pathEnd;

  /// The raw finger position during an active drag to act as the path leader.
  final Offset? dragOffset;
  final bool drawPath;
  final bool drawTip;

  PathPainter({
    required this.playerPath,
    required this.cellSize,
    required this.pathStart,
    required this.pathEnd,
    this.dragOffset,
    this.drawPath = true,
    this.drawTip = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pts = playerPath.points;
    if (pts.isEmpty) return;

    // ── Build the list of pixel centres to connect ──────────────────────────
    final List<Offset> points = [
      for (final p in pts) gridToPixel(p, cellSize),
    ];

    if (dragOffset != null) {
      points.add(dragOffset!);
    }

    if (drawPath) {

    // ── Primary path ────────────────────────────────────────────────────────
    final path = _buildPath(points);

    final Paint paint = Paint()
      ..strokeWidth = cellSize * 0.40
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Rect bounds = path.getBounds();
    if (bounds.width > 1 || bounds.height > 1) {
      paint.shader = LinearGradient(
        colors: [pathStart, pathEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds);
    } else {
      paint.color = pathStart;
    }

    canvas.drawPath(path, paint);

    // ── Inner highlight (3-D tube feel) ─────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = cellSize * 0.10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    }

    // ── Glowing tip dot ──────────────────────────────────────────────────────
    if (drawTip && points.isNotEmpty) {
      final tip = points.last;
      final dotR = cellSize * 0.22;

      // Outer soft glow.
      canvas.drawCircle(
        tip,
        dotR * 1.55,
        Paint()
          ..color = pathEnd.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill,
      );

      // Solid dot.
      canvas.drawCircle(tip, dotR, Paint()..color = pathEnd);

      // White core.
      canvas.drawCircle(
        tip,
        dotR * 0.42,
        Paint()..color = Colors.white.withValues(alpha: 0.80),
      );
    }
  }

  Path _buildPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx, points[0].dy);
    if (points.length == 1) {
      path.lineTo(points[0].dx, points[0].dy);
      return path;
    }

    final double cornerR = cellSize * 0.35;

    for (int i = 0; i < points.length - 1; i++) {
      final pCurr = points[i];
      final pNext = points[i + 1];

      if (i == points.length - 2) {
        // Last segment
        path.lineTo(pNext.dx, pNext.dy);
      } else {
        final pNextNext = points[i + 2];

        final v1 = pCurr - pNext;
        final d1 = v1.distance;
        
        final v2 = pNextNext - pNext;
        final d2 = v2.distance;

        // Prevent rendering artifacts if points are too close
        if (d1 < 1.0 || d2 < 1.0) {
           path.lineTo(pNext.dx, pNext.dy);
           continue;
        }

        final double r1 = math.min(cornerR, d1 / 2);
        final double r2 = math.min(cornerR, d2 / 2);

        final pCurveStart = pNext + (v1 / d1) * r1;
        final pCurveEnd = pNext + (v2 / d2) * r2;

        path.lineTo(pCurveStart.dx, pCurveStart.dy);
        path.quadraticBezierTo(pNext.dx, pNext.dy, pCurveEnd.dx, pCurveEnd.dy);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant PathPainter old) {
    return old.playerPath.points.length != playerPath.points.length ||
        old.dragOffset != dragOffset ||
        old.drawPath != drawPath ||
        old.drawTip != drawTip ||
        old.cellSize != cellSize ||
        old.pathStart != pathStart ||
        old.pathEnd != pathEnd;
  }
}
