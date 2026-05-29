import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/grid_pos.dart';

class WallPainter extends CustomPainter {
  final Board board;
  final double cellSize;
  final Color wallColor;

  WallPainter({
    required this.board,
    required this.cellSize,
    required this.wallColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Premium Drop Shadow Layer for Depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..strokeWidth = cellSize * 0.38
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // Thick Physical Blockage Layer
    final paint = Paint()
      ..color = wallColor
      ..strokeWidth = cellSize * 0.35
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    for (final wallKey in board.walls) {
      final parts = wallKey.split('-');
      if (parts.length == 2) {
        final p1 = parts[0].split(',');
        final p2 = parts[1].split(',');

        if (p1.length == 2 && p2.length == 2) {
          final x1 = int.parse(p1[0]);
          final y1 = int.parse(p1[1]);
          final x2 = int.parse(p2[0]);
          final y2 = int.parse(p2[1]);

          // The wall is drawn exactly on the border between cell1 and cell2
          // Find the midpoint border between them
          if (x1 == x2) {
            // Horizontal wall (separating top and bottom)
            final borderY = (mathMax(y1, y2)) * cellSize;
            final startX = x1 * cellSize + cellSize * 0.05;
            final endX = (x1 + 1) * cellSize - cellSize * 0.05;
            // Draw shadow then physical wall
            canvas.drawLine(Offset(startX, borderY + 2), Offset(endX, borderY + 2), shadowPaint);
            canvas.drawLine(Offset(startX, borderY), Offset(endX, borderY), paint);
          } else if (y1 == y2) {
            // Vertical wall (separating left and right)
            final borderX = (mathMax(x1, x2)) * cellSize;
            final startY = y1 * cellSize + cellSize * 0.05;
            final endY = (y1 + 1) * cellSize - cellSize * 0.05;
            // Draw shadow then physical wall
            canvas.drawLine(Offset(borderX + 2, startY), Offset(borderX + 2, endY), shadowPaint);
            canvas.drawLine(Offset(borderX, startY), Offset(borderX, endY), paint);
          }
        }
      }
    }
  }

  int mathMax(int a, int b) => a > b ? a : b;

  @override
  bool shouldRepaint(covariant WallPainter old) {
    return old.board.walls.length != board.walls.length ||
        old.cellSize != cellSize ||
        old.wallColor != wallColor;
  }
}
