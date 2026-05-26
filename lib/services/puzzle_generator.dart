import 'dart:math';
import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/grid_pos.dart';
import '../models/player_path.dart';
import '../models/puzzle_data.dart';
import '../models/difficulty.dart';

class PuzzleGenerator {
  final Random _rnd = Random();

  Future<PuzzleData> generate(Difficulty difficulty) async {
    int size = _getSize(difficulty);
    int nodeCount = _getNodeCount(difficulty, size);
    bool useWalls = _usesWalls(difficulty);

    Board board = Board(size);
    
    // 1. Generate Walls (if applicable)
    if (useWalls) {
      _generateWalls(board, difficulty);
    }

    // 2. Find Hamiltonian Path
    List<GridPos> path = await _findHamiltonianPath(board);
    if (path.isEmpty) {
      // Fallback if no path found with walls (very rare with good wall placement, but possible)
      // Retry without walls or fewer walls. For simplicity, just regenerate a simple one.
      return generate(Difficulty.beginner);
    }

    // 3. Place Nodes
    board.totalNodes = nodeCount;
    List<int> nodeIndices = _distributeNodes(path.length, nodeCount);
    
    for (int i = 0; i < nodeIndices.length; i++) {
      final pos = path[nodeIndices[i]];
      // Just cycle some bright colors for the nodes
      final color = Colors.primaries[i % Colors.primaries.length];
      board.setNode(pos, i + 1, color);
    }

    // 4. Create Solution Path
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

  int _getNodeCount(Difficulty diff, int size) {
    switch (diff) {
      case Difficulty.beginner: return 4;
      case Difficulty.medium: return 6;
      case Difficulty.hard: return 8;
    }
  }

  bool _usesWalls(Difficulty diff) {
    return diff == Difficulty.medium || diff == Difficulty.hard;
  }

  void _generateWalls(Board board, Difficulty diff) {
    // Randomly place a few walls to increase complexity without entirely blocking the board.
    int wallCount = diff == Difficulty.hard ? 5 : 2;
    
    int added = 0;
    int attempts = 0;
    while (added < wallCount && attempts < 50) {
      attempts++;
      int x = _rnd.nextInt(board.size);
      int y = _rnd.nextInt(board.size);
      bool horizontal = _rnd.nextBool();
      
      GridPos a = GridPos(x, y);
      GridPos b = horizontal ? GridPos(x + 1, y) : GridPos(x, y + 1);
      
      if (board.isValidPos(b) && !board.hasWall(a, b)) {
        board.addWall(a, b);
        added++;
      }
    }
  }

  List<int> _distributeNodes(int pathLength, int nodeCount) {
    List<int> indices = [0, pathLength - 1]; // Start and end are always nodes
    int remaining = nodeCount - 2;
    if (remaining <= 0) return indices;

    int step = pathLength ~/ (remaining + 1);
    for (int i = 1; i <= remaining; i++) {
      int offset = _rnd.nextInt(step ~/ 2) - (step ~/ 4);
      int idx = (i * step) + offset;
      idx = idx.clamp(1, pathLength - 2);
      if (!indices.contains(idx)) {
        indices.add(idx);
      } else {
        // Find nearest empty
        for (int j = idx + 1; j < pathLength - 1; j++) {
          if (!indices.contains(j)) { indices.add(j); break; }
        }
      }
    }
    indices.sort();
    return indices;
  }

  Future<List<GridPos>> _findHamiltonianPath(Board board) async {
    // For smaller boards, standard DFS backtracking works.
    // We use Warnsdorff's heuristic: prefer cells with fewer unvisited neighbors.
    final totalCells = board.size * board.size;
    List<GridPos> path = [];
    Set<String> visited = {};
    
    // Start from a random edge or corner to improve success rate
    List<GridPos> starts = [];
    for (int i = 0; i < board.size; i++) {
      starts.add(GridPos(i, 0));
      starts.add(GridPos(i, board.size - 1));
      starts.add(GridPos(0, i));
      starts.add(GridPos(board.size - 1, i));
    }
    starts.shuffle(_rnd);
    
    GridPos start = starts.first;

    bool solve(GridPos current) {
      path.add(current);
      visited.add('${current.x},${current.y}');

      if (path.length == totalCells) {
        return true; // Found!
      }

      // Get valid adjacent
      List<GridPos> neighbors = board.getAdjacent(current)
          .where((p) => !visited.contains('${p.x},${p.y}') && !board.hasWall(current, p))
          .toList();

      // Sort by fewest available neighbors (Warnsdorff)
      neighbors.sort((a, b) {
        int aMoves = board.getAdjacent(a).where((p) => !visited.contains('${p.x},${p.y}') && !board.hasWall(a, p)).length;
        int bMoves = board.getAdjacent(b).where((p) => !visited.contains('${p.x},${p.y}') && !board.hasWall(b, p)).length;
        return aMoves.compareTo(bMoves);
      });

      for (final next in neighbors) {
        if (solve(next)) {
          return true;
        }
      }

      // Backtrack
      path.removeLast();
      visited.remove('${current.x},${current.y}');
      return false;
    }

    // Try up to 3 different start positions if first fails
    for (int i = 0; i < min(3, starts.length); i++) {
      if (solve(starts[i])) return path;
    }
    
    return [];
  }
}
