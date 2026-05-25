import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../models/tile.dart';

class TileWidget extends StatelessWidget {
  final Tile tile;
  final double size;
  final int index;
  final bool isPathActive;

  const TileWidget({
    Key? key,
    required this.tile,
    required this.size,
    required this.index,
    this.isPathActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNode = tile.type == TileType.node;
    final bool isIce = tile.type == TileType.ice;
    final bool isWarp = tile.type == TileType.warp;
    final theme = context.zipTheme;

    // Adaptive text color for nodes based on background brightness
    final nodeTextColor = theme.node.computeLuminance() > 0.50
        ? (theme.isDark ? theme.boardBackground : theme.textPrimary)
        : Colors.white;

    // Theme-aware dynamic contrast styles for path tiles & empty cells
    final Color cellColor;
    final Border cellBorder;
    if (isPathActive) {
      cellColor = theme.pathStart.withValues(alpha: 0.15);
      cellBorder = Border.all(
        color: theme.pathStart.withValues(alpha: 0.35),
        width: 1.5,
      );
    } else {
      if (theme.isBoardDark) {
        cellColor = theme.surfaceAlt.withValues(alpha: 0.35);
        cellBorder = Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        );
      } else {
        cellColor = theme.surface.withValues(alpha: 0.70);
        cellBorder = Border.all(
          color: theme.textPrimary.withValues(alpha: 0.08),
          width: 1.0,
        );
      }
    }

    Widget content = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Background cell ────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: size * 0.95,
            height: size * 0.95,
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(size * 0.15),
              border: cellBorder,
            ),
          ),

          // TODO: Hook up physics logic here for Ice and Warp cells

          // ── Ice Obstacle ───────────────────────────────────────────────────
          if (isIce)
            Container(
              width: size * 0.85,
              height: size * 0.85,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.3),
                borderRadius: BorderRadius.circular(size * 0.1),
                border: Border.all(color: Colors.cyanAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.ac_unit, color: Colors.cyanAccent, size: size * 0.5),
            ),

          // ── Warp Obstacle ──────────────────────────────────────────────────
          if (isWarp)
            Container(
              width: size * 0.75,
              height: size * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Colors.purpleAccent, Colors.deepPurple],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.all_out, color: Colors.white, size: 20),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3.seconds),

          // ── Node ───────────────────────────────────────────────────────────

          if (isNode)
            Container(
                  width: size * 0.60,
                  height: size * 0.60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.node,
                    boxShadow: [
                      BoxShadow(
                        color: theme.glow.withValues(
                          alpha: isPathActive ? 0.55 : 0.18,
                        ),
                        blurRadius: isPathActive ? 10 : 4,
                        spreadRadius: isPathActive ? 2 : 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${tile.sequenceNum}',
                      style: TextStyle(
                        color: nodeTextColor,
                        fontSize: size * 0.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
                // Node pops slightly larger when path arrives at it.
                .animate(target: isPathActive ? 1 : 0)
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.15, 1.15),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),

        ],
      ),
    );

    // Board entrance animation: staggered scale-in from zero.
    return content
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
          delay: (index * 8).ms,
          duration: 340.ms,
        )
        .fadeIn(delay: (index * 8).ms, duration: 260.ms);
  }
}
