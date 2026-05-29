import 'dart:math';
import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/grid_pos.dart';
import '../models/player_path.dart';
import '../models/puzzle_data.dart';
import '../models/difficulty.dart';

class LevelGenerator {
  // Static wrapper for compute() isolate execution
  static Future<PuzzleData> generateIsolate(Map<String, dynamic> args) async {
    Difficulty diff = args['diff'];
    int levelId = args['levelId'];
    return LevelGenerator().generateSync(diff, levelId);
  }

  // Synchronous generation for isolate processing
  PuzzleData generateSync(Difficulty difficulty, int levelId) {
    final Random rnd = Random(levelId + difficulty.hashCode * 1000);
    
    int size = _getSize(difficulty);
    Board board = Board(size);
    
    int phase = ((levelId - 1) % 100) + 1;
    
    // 1. Structural Topology Generation
    if (phase > 25 && phase <= 50) {
      _buildZigZagTraps(board, size, rnd);
    } else if (phase > 50 && phase <= 75) {
      _buildBipartiteBridge(board, size, rnd);
    } else if (phase > 75) {
      _buildConcentricSpiral(board, size, rnd);
    }

    // 2. Fast Hamiltonian Path Carving
    List<GridPos> path = _findHamiltonianSnake(board, size, rnd);
    
    // If structured walls blocked the pathing completely, relax them and try again
    int expectedTiles = size * size;
    int retries = 0;
    while ((path.isEmpty || path.length < expectedTiles) && retries < 10) {
      board = Board(size); // Reset board
      // Apply a lighter constraint
      if (retries < 5) {
        if (phase > 75) _buildZigZagTraps(board, size, rnd); // Fallback to zig-zag
      }
      path = _findHamiltonianSnake(board, size, rnd);
      retries++;
    }
    
    if (path.length < expectedTiles) {
      // Ultimate fallback: completely open board guarantees 100% density
      board = Board(size);
      path = _findHamiltonianSnake(board, size, rnd);
    }

    // 3. Hint Starvation Logic
    int hintCount = max(2, 6 - (phase ~/ 20));
    if (phase > 80) hintCount = 2; // Strict starvation (Start and End only)
    
    List<int> nodeIndices = _selectMaliciousHintIndices(path, hintCount, phase / 100.0, rnd);
    
    board.totalNodes = nodeIndices.length;
    for (int i = 0; i < nodeIndices.length; i++) {
      final pos = path[nodeIndices[i]];
      // Deterministic distinct colors
      final color = Colors.primaries[(i * 3 + levelId) % Colors.primaries.length];
      board.setNode(pos, i + 1, color);
    }
    
    // 4. Fill Solution
    PlayerPath solution = PlayerPath();
    for (final p in path) {
      solution.addPoint(p);
    }
    
    return PuzzleData(board: board, solution: solution);
  }

  int _getSize(Difficulty diff) {
    switch (diff) {
      case Difficulty.beginner: return 5;
      case Difficulty.medium: return 7;
      case Difficulty.hard: return 9;
    }
  }

  // Phase 2: Zig-Zag traps and dead-end baits
  void _buildZigZagTraps(Board board, int size, Random rnd) {
    int wallCount = size == 9 ? 8 : (size == 7 ? 5 : 2);
    int added = 0;
    for (int i = 0; i < 50 && added < wallCount; i++) {
      int x = rnd.nextInt(size);
      int y = rnd.nextInt(size);
      bool horizontal = rnd.nextBool();
      GridPos a = GridPos(x, y);
      GridPos b = horizontal ? GridPos(x + 1, y) : GridPos(x, y + 1);
      
      if (b.x < size && b.y < size && !board.hasWall(a, b)) {
        board.addWall(a, b);
        added++;
      }
    }
  }

  // Phase 3: The Bipartite Bridge
  void _buildBipartiteBridge(Board board, int size, Random rnd) {
    int splitY = size ~/ 2;
    int gateX = rnd.nextInt(size);
    // Draw a horizontal line of walls dividing top and bottom, except for the gate
    for (int x = 0; x < size; x++) {
      if (x != gateX) {
        board.addWall(GridPos(x, splitY), GridPos(x, splitY + 1));
      }
    }
  }

  // Phase 4: Concentric Spiral (Outer to Inner)
  void _buildConcentricSpiral(Board board, int size, Random rnd) {
    // Generate a basic spiral wall structure by slicing concentric rings
    int layers = size ~/ 2;
    for (int l = 0; l < layers; l++) {
      int minXY = l;
      int maxXY = size - 1 - l;
      
      // Leave one gap per ring to spiral inward
      int gapSide = rnd.nextInt(4); // 0=top, 1=right, 2=bottom, 3=left
      
      // Top wall
      for (int x = minXY; x < maxXY; x++) {
        if (gapSide != 0 || x != minXY + (maxXY - minXY) ~/ 2) {
          if (minXY > 0) board.addWall(GridPos(x, minXY), GridPos(x, minXY - 1));
        }
      }
      // Right wall
      for (int y = minXY; y < maxXY; y++) {
        if (gapSide != 1 || y != minXY + (maxXY - minXY) ~/ 2) {
          if (maxXY < size - 1) board.addWall(GridPos(maxXY, y), GridPos(maxXY + 1, y));
        }
      }
      // Bottom wall
      for (int x = minXY + 1; x <= maxXY; x++) {
        if (gapSide != 2 || x != minXY + (maxXY - minXY) ~/ 2) {
          if (maxXY < size - 1) board.addWall(GridPos(x, maxXY), GridPos(x, maxXY + 1));
        }
      }
      // Left wall
      for (int y = minXY + 1; y <= maxXY; y++) {
        if (gapSide != 3 || y != minXY + (maxXY - minXY) ~/ 2) {
          if (minXY > 0) board.addWall(GridPos(minXY, y), GridPos(minXY - 1, y));
        }
      }
    }
  }

  // Fast Snake Generator (0ms validation loop)
  List<GridPos> _findHamiltonianSnake(Board board, int size, Random rnd) {
    int targetLength = size * size;
    List<GridPos> bestPath = [];
    
    // We try to fill the board by snaking.
    for (int attempt = 0; attempt < 500; attempt++) {
      List<GridPos> path = [];
      Set<String> visited = {};
      
      // Prefer starting in corners to maximize filling
      GridPos current = GridPos(rnd.nextBool() ? 0 : size - 1, rnd.nextBool() ? 0 : size - 1);
      path.add(current);
      visited.add('${current.x},${current.y}');
      
      while (true) {
        List<GridPos> neighbors = [];
        if (current.x > 0) neighbors.add(GridPos(current.x - 1, current.y));
        if (current.x < size - 1) neighbors.add(GridPos(current.x + 1, current.y));
        if (current.y > 0) neighbors.add(GridPos(current.x, current.y - 1));
        if (current.y < size - 1) neighbors.add(GridPos(current.x, current.y + 1));
        
        // Filter out visited and walled neighbors
        neighbors.removeWhere((p) => visited.contains('${p.x},${p.y}') || board.hasWall(current, p));
        
        // --- PHASE 2: O(1) GRAPH PRUNING (EARLY ABORT HEURISTIC) ---
        // If placing the current block isolated any of its immediate empty neighbors, abort.
        bool isolatedCellDetected = false;
        List<GridPos> adjacents = [
          GridPos(current.x - 1, current.y),
          GridPos(current.x + 1, current.y),
          GridPos(current.x, current.y - 1),
          GridPos(current.x, current.y + 1),
        ];

        for (final check in adjacents) {
          if (check.x >= 0 && check.x < size && check.y >= 0 && check.y < size) {
            if (!visited.contains('${check.x},${check.y}')) {
              int blockedSides = 0;
              if (check.x == 0 || visited.contains('${check.x-1},${check.y}') || board.hasWall(check, GridPos(check.x-1, check.y))) blockedSides++;
              if (check.x == size-1 || visited.contains('${check.x+1},${check.y}') || board.hasWall(check, GridPos(check.x+1, check.y))) blockedSides++;
              if (check.y == 0 || visited.contains('${check.x},${check.y-1}') || board.hasWall(check, GridPos(check.x, check.y-1))) blockedSides++;
              if (check.y == size-1 || visited.contains('${check.x},${check.y+1}') || board.hasWall(check, GridPos(check.x, check.y+1))) blockedSides++;
              
              if (blockedSides >= 4) {
                isolatedCellDetected = true;
                break;
              }
            }
          }
        }

        if (isolatedCellDetected || neighbors.isEmpty) break;
        
        GridPos next = neighbors[rnd.nextInt(neighbors.length)];
        
        // Weight going straight to form clean lines
        if (path.length > 1) {
          GridPos prev = path[path.length - 2];
          int dx = current.x - prev.x;
          int dy = current.y - prev.y;
          GridPos straight = GridPos(current.x + dx, current.y + dy);
          if (neighbors.any((p) => p.x == straight.x && p.y == straight.y)) {
             if (rnd.nextDouble() < 0.75) {
               next = straight;
             }
          }
        }
        
        current = next;
        path.add(current);
        visited.add('${current.x},${current.y}');
      }
      
      if (path.length > bestPath.length) {
        bestPath = path;
      }
      if (bestPath.length == targetLength) {
        return bestPath;
      }
    }
    
    return bestPath;
  }

  // Deceptive Dead-End Bait Hint Placement
  List<int> _selectMaliciousHintIndices(List<GridPos> path, int requiredNodes, double progress, Random rnd) {
    List<int> indices = [0, path.length - 1]; // Start and end are strictly maintained
    int needed = requiredNodes - 2;
    if (needed <= 0) return indices;

    List<Map<String, dynamic>> nodeScores = [];
    for (int i = 1; i < path.length - 1; i++) {
      GridPos prev = path[i - 1];
      GridPos curr = path[i];
      GridPos next = path[i + 1];
      bool isCorner = (prev.y == curr.y) != (curr.y == next.y);
      
      // The Bait: Assign high scores to corners early on, but heavily bait dead-ends later
      double structuralScore = isCorner ? 1.0 : -1.0;
      double progressWeight = 1.0 - (progress * 2.0);
      
      double finalScore = (structuralScore * progressWeight) + (rnd.nextDouble() * 0.5);
      nodeScores.add({'index': i, 'score': finalScore});
    }

    nodeScores.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    for (int i = 0; i < min(needed, nodeScores.length); i++) {
      indices.add(nodeScores[i]['index']);
    }
    
    indices.sort();
    return indices;
  }
}
