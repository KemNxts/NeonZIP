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
    final theme = context.zipTheme;
    final nodeTextColor = theme.node.computeLuminance() > 0.55
        ? theme.textPrimary
        : Colors.white;

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
              color: isPathActive
                  ? theme.pathStart.withValues(alpha: 0.08)
                  : theme.surface.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(size * 0.15),
            ),
          ),

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
                  end: const Offset(1.08, 1.08),
                  duration: 280.ms,
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
