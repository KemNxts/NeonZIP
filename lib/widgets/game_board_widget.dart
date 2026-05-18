import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../models/board.dart';
import '../models/grid_pos.dart';
import '../services/game_state_manager.dart';
import 'path_painter.dart';
import 'tile_widget.dart';

class GameBoardWidget extends StatefulWidget {
  const GameBoardWidget({Key? key}) : super(key: key);

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget> {
  /// True while the user's finger is actively dragging (pan recognised).
  /// False during tap-based auto-extension, undo, and reset.
  bool _isDragging = false;

  /// Raw offset of the user's finger, clamped to orthogonal movements from the last cell.
  Offset? _dragOffset;

  /// Cached layout values so onTapUp can resolve a grid position.
  double _cellSize = 0;
  int _gridSize = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateManager>(
      builder: (context, state, child) {
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

            // Cache layout values for use in onTapUp (outside LayoutBuilder).
            _cellSize = cellSize;
            _gridSize = size;

            return Center(
              child: Container(
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
                          
                          // 2. Clipped Path
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: CustomPaint(
                                painter: PathPainter(
                                  playerPath: state.playerPath,
                                  cellSize: cellSize,
                                  pathStart: theme.pathStart,
                                  pathEnd: theme.pathEnd,
                                  dragOffset: _isDragging ? _dragOffset : null,
                                  drawPath: true,
                                  drawTip: false,
                                ),
                              ),
                            ),
                          ),
                          
                          // 3. Unclipped Active Pointer
                          SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: PathPainter(
                                  playerPath: state.playerPath,
                                  cellSize: cellSize,
                                  pathStart: theme.pathStart,
                                  pathEnd: theme.pathEnd,
                                  dragOffset: _isDragging ? _dragOffset : null,
                                  drawPath: false,
                                  drawTip: true,
                                ),
                              ),
                            ),
                          ),
                          
                          // 4. Clipped Nodes & UI
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
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
                                      final isNextValid = nextX >= 0 && nextX < size;
                                      
                                      double dragVal = diff.dx;
                                      if (!isNextValid) {
                                        // Dragging against the board edge!
                                        final maxAllowed = cellSize * 0.5;
                                        // Soft magnetic resistance near edge
                                        final double norm = dragVal.abs() / maxAllowed;
                                        final double t = norm > 20.0 ? 1.0 : (math.exp(2 * norm) - 1) / (math.exp(2 * norm) + 1);
                                        final double res = maxAllowed * t;
                                        dragVal = isRight ? res : -res;
                                      } else {
                                        dragVal = dragVal.clamp(-cellSize, cellSize);
                                      }
                                      clampedDiff = Offset(dragVal, 0);
                                    } else {
                                      // Vertical drag
                                      final isDown = diff.dy > 0;
                                      final nextY = isDown ? lastPos.y + 1 : lastPos.y - 1;
                                      final isNextValid = nextY >= 0 && nextY < size;
                                      
                                      double dragVal = diff.dy;
                                      if (!isNextValid) {
                                        // Dragging against the board edge!
                                        final maxAllowed = cellSize * 0.5;
                                        // Soft magnetic resistance near edge
                                        final double norm = dragVal.abs() / maxAllowed;
                                        final double t = norm > 20.0 ? 1.0 : (math.exp(2 * norm) - 1) / (math.exp(2 * norm) + 1);
                                        final double res = maxAllowed * t;
                                        dragVal = isDown ? res : -res;
                                      } else {
                                        dragVal = dragVal.clamp(-cellSize, cellSize);
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
                                // Tap up fires only for clean taps (no drag recognised).
                                onTapUp: (details) {
                                  setState(() {
                                    _isDragging = false;
                                    _dragOffset = null;
                                  });
                                  final GridPos pos = _getGridPos(
                                    details.localPosition,
                                    _cellSize,
                                    _gridSize,
                                  );
                                  state.tapExtendPath(pos);
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
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 400.ms),
            );
          },
        );
      },
    );
  }

  GridPos _getGridPos(Offset localPosition, double cellSize, int size) {
    final int x = (localPosition.dx / cellSize).floor();
    final int y = (localPosition.dy / cellSize).floor();
    return GridPos(x.clamp(0, size - 1), y.clamp(0, size - 1));
  }
}
