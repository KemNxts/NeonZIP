import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../models/board.dart';
import '../models/grid_pos.dart';
import '../services/game_state_manager.dart';
import '../services/settings_service.dart';
import 'particle_layer.dart';
import '../models/tile.dart';
import 'path_painter.dart';
import 'tile_widget.dart';
import 'wall_painter.dart';

class GameBoardWidget extends StatefulWidget {
  const GameBoardWidget({Key? key}) : super(key: key);

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget>
    with SingleTickerProviderStateMixin {
  /// True while the user's finger is actively dragging (pan recognised).
  /// False during tap-based auto-extension, undo, and reset.
  bool _isDragging = false;

  /// Raw offset of the user's finger, clamped to orthogonal movements from the last cell.
  Offset? _dragOffset;

  final GlobalKey<ParticleLayerState> _particleLayerKey = GlobalKey<ParticleLayerState>();
  late AnimationController _blastController;
  bool _wasAnimatingBlast = false;

  @override
  void initState() {
    super.initState();
    _blastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _blastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameStateManager, SettingsService>(
      builder: (context, state, settings, child) {
        // Trigger blast animation
        if (state.isAnimatingBlast && !_wasAnimatingBlast) {
          _wasAnimatingBlast = true;
          _blastController.forward(from: 0.0);
          
          // Spawn confetti bursts sequentially along the path
          if (state.playerPath.points.isNotEmpty) {
            final points = state.playerPath.points;
            final double cellW = (MediaQuery.of(context).size.width * 0.95) / state.board!.size;
            for (int i = 0; i < points.length; i++) {
              Future.delayed(Duration(milliseconds: (1000 ~/ points.length) * i), () {
                if (mounted && _particleLayerKey.currentState != null) {
                   final pos = points[i];
                   final pixelPos = Offset(pos.x * cellW + cellW / 2, pos.y * cellW + cellW / 2);
                   _particleLayerKey.currentState!.burst(
                     pixelPos, 
                     5, 
                     Colors.white,
                     speedMultiplier: 2.0
                   );
                }
              });
            }
          }
        } else if (!state.isAnimatingBlast && _wasAnimatingBlast) {
          _wasAnimatingBlast = false;
        }
        final theme = context.zipTheme;
        if (state.board == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final Board board = state.board!;
        final int size = board.size;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double minDimension = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
            final double boardSize = minDimension * 0.95;
            final double cellSize = boardSize / size;

            return Center(
              child: ValueListenableBuilder<int>(
                valueListenable: state.invalidMoveTrigger,
                builder: (context, errorTrigger, _) {
                  Widget boardWidget = Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(32.0),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadow,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: boardSize,
                      height: boardSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 1. Board Background
                          Container(
                            decoration: BoxDecoration(
                              color: theme.boardBackground,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                          ),
                          
                          // 1.5. Background Cells
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: IgnorePointer(
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: size,
                                  ),
                                  itemCount: size * size,
                                  itemBuilder: (context, index) {
                                    final int x = index % size;
                                    final int y = index ~/ size;
                                    final pos = GridPos(x, y);
                                    final tile = board.getTile(pos);
                                    final bool isPathActive = state.playerPath.contains(pos);
                                    return TileWidget(
                                      tile: tile,
                                      size: cellSize,
                                      index: index,
                                      isPathActive: isPathActive,
                                      layer: TileLayer.background,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          
                          // 2. Clipped Path
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: RepaintBoundary(
                                child: AnimatedBuilder(
                                  animation: _blastController,
                                  builder: (context, _) {
                                    return CustomPaint(
                                      painter: PathPainter(
                                        playerPath: state.playerPath,
                                        cellSize: cellSize,
                                        pathStart: theme.pathStart,
                                        pathEnd: theme.pathEnd,
                                        dragOffset: _isDragging ? _dragOffset : null,
                                        drawPath: true,
                                        drawTip: false,
                                        style: settings.pathStyle,
                                        blastProgress: state.isAnimatingBlast ? _blastController.value : null,
                                      ),
                                    );
                                  }
                                ),
                              ),
                            ),
                          ),
                          
                          // 3. Unclipped Active Pointer
                          SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: PathPainter(
                                    playerPath: state.playerPath,
                                    cellSize: cellSize,
                                    pathStart: theme.pathStart,
                                    pathEnd: theme.pathEnd,
                                    dragOffset: _isDragging ? _dragOffset : null,
                                    drawPath: false,
                                    drawTip: true,
                                    style: settings.pathStyle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 3.5 Particle System (Trails)
                          SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: ParticleLayer(
                              key: _particleLayerKey,
                              dragOffset: _isDragging ? _dragOffset : null,
                              particleColor: theme.pathStart,
                            ),
                          ),
                          
                          // 4. Clipped Nodes & UI
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: Listener(
                                onPointerUp: (event) {
                                  setState(() {
                                    _isDragging = false;
                                    _dragOffset = null;
                                  });
                                  final GridPos pos = _getGridPos(
                                    event.localPosition,
                                    cellSize,
                                    size,
                                  );
                                  state.tapExtendPath(pos);
                                },
                                child: GestureDetector(
                                  // Pan down fires immediately — used to start/re-engage
                                  // an existing path or tap on node 1.
                                  onPanDown: (details) {
                                  final GridPos pos = _getGridPos(
                                    details.localPosition,
                                    cellSize,
                                    size,
                                  );
                                  state.handleInput(pos);
                                },
                                // Pan start fires only after movement is confirmed.
                                onPanStart: (_) => setState(() => _isDragging = true),
                                onPanUpdate: (details) {
                                  if (state.playerPath.points.isNotEmpty) {
                                    final lastPos = state.playerPath.points.last;
                                    final lastPixel = Offset(
                                      lastPos.x * cellSize + cellSize / 2,
                                      lastPos.y * cellSize + cellSize / 2,
                                    );
                                    
                                    final diff = details.localPosition - lastPixel;
                                    
                                    Offset clampedDiff = Offset.zero;
                                    if (diff.dx.abs() > diff.dy.abs()) {
                                      // Horizontal drag
                                      final isRight = diff.dx > 0;
                                      final nextX = isRight ? lastPos.x + 1 : lastPos.x - 1;
                                      final nextPos = GridPos(nextX, lastPos.y);
                                      final isNextValid = _isValidNextStep(state, nextPos, size);
                                      
                                      double dragVal = diff.dx;
                                      if (!isNextValid) {
                                        // Treat invalid next cells as blocked (no visual stretch/overlap)
                                        dragVal = 0.0;
                                      } else {
                                        dragVal = dragVal.clamp(-cellSize * 0.30, cellSize * 0.30);
                                      }
                                      clampedDiff = Offset(dragVal, 0);
                                    } else {
                                      // Vertical drag
                                      final isDown = diff.dy > 0;
                                      final nextY = isDown ? lastPos.y + 1 : lastPos.y - 1;
                                      final nextPos = GridPos(lastPos.x, nextY);
                                      final isNextValid = _isValidNextStep(state, nextPos, size);
                                      
                                      double dragVal = diff.dy;
                                      if (!isNextValid) {
                                        // Treat invalid next cells as blocked (no visual stretch/overlap)
                                        dragVal = 0.0;
                                      } else {
                                        dragVal = dragVal.clamp(-cellSize * 0.30, cellSize * 0.30);
                                      }
                                      clampedDiff = Offset(0, dragVal);
                                    }
                                    
                                    setState(() {
                                      _dragOffset = lastPixel + clampedDiff;
                                      _isDragging = true;
                                    });
                                  }

                                  final GridPos pos = _getGridPos(
                                    details.localPosition,
                                    cellSize,
                                    size,
                                  );
                                  state.handleDragUpdate(pos);
                                },
                                onPanEnd: (details) {
                                  setState(() {
                                    _isDragging = false;
                                    _dragOffset = null;
                                  });
                                  state.handleDragEnd();
                                },
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: size,
                                      ),
                                  itemCount: size * size,
                                  itemBuilder: (context, index) {
                                    final int x = index % size;
                                    final int y = index ~/ size;
                                    final pos = GridPos(x, y);
                                    final tile = board.getTile(pos);
                                    final bool isPathActive =
                                        state.playerPath.contains(pos);
                                    return TileWidget(
                                      tile: tile,
                                      size: cellSize,
                                      index: index,
                                      isPathActive: isPathActive,
                                      layer: TileLayer.foreground,
                                    );
                                  },
                                ),
                                ),
                              ),
                            ),
                          ),


                          // 5. Walls Layer
                          IgnorePointer(
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: CustomPaint(
                                painter: WallPainter(
                                  board: board,
                                  cellSize: cellSize,
                                  wallColor: theme.isDark 
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : theme.textPrimary.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (errorTrigger > 0) {
                    boardWidget = boardWidget
                        .animate(key: ValueKey('error_$errorTrigger'))
                        .shakeX(hz: 8, amount: 6, duration: 400.ms);
                  }

                  return boardWidget
                    .animate()
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 400.ms);
                },
              ),
            );
          },

        );
      },
    );
  }

  bool _isValidNextStep(GameStateManager state, GridPos nextPos, int size) {
    if (state.board == null) return false;
    if (nextPos.x < 0 || nextPos.x >= size || nextPos.y < 0 || nextPos.y >= size) return false;
    if (state.playerPath.contains(nextPos)) return false;

    if (state.playerPath.points.isNotEmpty) {
      if (state.board!.hasWall(state.playerPath.points.last, nextPos)) return false;
    }

    final tile = state.board!.getTile(nextPos);
    if (tile.type == TileType.node) {
      int expectedNext = 2;
      for (var p in state.playerPath.points) {
        var t = state.board!.getTile(p);
        if (t.type == TileType.node) {
          expectedNext = t.sequenceNum + 1;
        }
      }
      if (tile.sequenceNum != expectedNext) {
        return false;
      }
    }
    return true;
  }

  GridPos _getGridPos(Offset localPosition, double cellSize, int size) {
    final int x = (localPosition.dx / cellSize).floor();
    final int y = (localPosition.dy / cellSize).floor();
    return GridPos(x.clamp(0, size - 1), y.clamp(0, size - 1));
  }
}
