import 'dart:math';
import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/grid_pos.dart';
import '../models/player_path.dart';
import '../models/puzzle_data.dart';
import '../models/difficulty.dart';

class LevelGenerator {
  Future<PuzzleData> generate(Difficulty difficulty, int levelId) async {
    // Deterministic seed ensures the same level number always yields the same puzzle
    final Random rnd = Random(levelId + difficulty.hashCode);
    
    int size = _getSize(difficulty);
    Board board = Board(size);
    
    // 1. Generate Walls (if applicable)
    if (_usesWalls(difficulty)) {
      _generateWalls(board, difficulty, rnd);
    }

    // 2. Hamiltonian Path Generation & Scoring (The Winding Rule)
    int pathsToGenerate = 15; // Generate a pool of valid paths to select from
    List<List<GridPos>> candidates = [];
    
    for (int i = 0; i < pathsToGenerate; i++) {
      List<GridPos> path = await _findHamiltonianPath(board, rnd);
      if (path.isNotEmpty) {
        candidates.add(path);
      }
    }

    if (candidates.isEmpty) {
      // Fallback: relax walls and try again
      board = Board(size);
      List<GridPos> path = await _findHamiltonianPath(board, rnd);
      if (path.isNotEmpty) {
        candidates.add(path);
      } else {
        throw Exception('Failed to generate a valid level for $difficulty $levelId');
      }
    }

    // Sort paths by complexity (Turn Count)
    candidates.sort((a, b) => _countTurns(a).compareTo(_countTurns(b)));

    // Level progression curve (0.0 to 1.0)
    double progress = ((levelId - 1) / 99.0).clamp(0.0, 1.0);

    // Winding Rule: Early levels get simple paths (low turns). Late levels get complex paths (high turns).
    int selectedPathIndex = (progress * (candidates.length - 1)).round();
    List<GridPos> finalPath = candidates[selectedPathIndex];

    // 3. Dynamic Hint Sparsity & Malicious Placement
    double revealPercent = 0.40 - (progress * 0.35); // 40% to 5%
    int nodeCount = max(3, (finalPath.length * revealPercent).ceil());
    
    List<int> nodeIndices = _selectMaliciousHintIndices(finalPath, nodeCount, progress, rnd);
    
    board.totalNodes = nodeIndices.length;
    
    for (int i = 0; i < nodeIndices.length; i++) {
      final pos = finalPath[nodeIndices[i]];
      // Deterministic color assignment based on sequence
      final color = Colors.primaries[(i * 3 + levelId) % Colors.primaries.length];
      board.setNode(pos, i + 1, color);
    }

    // 4. Create Solution Path
    PlayerPath solution = PlayerPath();
    for (final p in finalPath) {
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

  bool _usesWalls(Difficulty diff) {
    return diff == Difficulty.medium || diff == Difficulty.hard;
  }

  void _generateWalls(Board board, Difficulty diff, Random rnd) {
    int wallCount = diff == Difficulty.hard ? 6 : 3;
    int added = 0;
    int attempts = 0;
    while (added < wallCount && attempts < 50) {
      attempts++;
      int x = rnd.nextInt(board.size);
      int y = rnd.nextInt(board.size);
      bool horizontal = rnd.nextBool();
      
      GridPos a = GridPos(x, y);
      GridPos b = horizontal ? GridPos(x + 1, y) : GridPos(x, y + 1);
      
      if (board.isValidPos(b) && !board.hasWall(a, b)) {
        // Simple check to ensure we don't block corners entirely
        int aNeighbors = board.getAdjacent(a).length;
        int bNeighbors = board.getAdjacent(b).length;
        if (aNeighbors > 2 && bNeighbors > 2) {
          board.addWall(a, b);
          added++;
        }
      }
    }
  }

  int _countTurns(List<GridPos> path) {
    int turns = 0;
    if (path.length < 3) return 0;
    for (int i = 1; i < path.length - 1; i++) {
      GridPos prev = path[i - 1];
      GridPos curr = path[i];
      GridPos next = path[i + 1];
      bool horizontal1 = prev.y == curr.y;
      bool horizontal2 = curr.y == next.y;
      if (horizontal1 != horizontal2) {
        turns++;
      }
    }
    return turns;
  }

  List<int> _selectMaliciousHintIndices(List<GridPos> path, int requiredNodes, double progress, Random rnd) {
    List<int> indices = [0, path.length - 1]; // Start and end are ALWAYS revealed
    int needed = requiredNodes - 2;
    if (needed <= 0) return indices;

    // Evaluate each inner node
    List<Map<String, dynamic>> nodeScores = [];
    for (int i = 1; i < path.length - 1; i++) {
      GridPos prev = path[i - 1];
      GridPos curr = path[i];
      GridPos next = path[i + 1];
      bool isCorner = (prev.y == curr.y) != (curr.y == next.y);
      
      // Early levels (progress ~0.0): Positive score for corners, negative for straights.
      // Late levels (progress ~1.0): Negative score for corners, positive for straights.
      double structuralScore = isCorner ? 1.0 : -1.0;
      double progressWeight = 1.0 - (progress * 2.0); // 1.0 to -1.0
      
      double finalScore = (structuralScore * progressWeight) + (rnd.nextDouble() * 0.5);
      nodeScores.add({'index': i, 'score': finalScore});
    }

    // Sort descending by score
    nodeScores.sort((a, b) => b['score'].compareTo(a['score']));
    
    // Pick the best `needed` nodes
    for (int i = 0; i < needed; i++) {
      indices.add(nodeScores[i]['index']);
    }
    
    indices.sort();
    return indices;
  }

  Future<List<GridPos>> _findHamiltonianPath(Board board, Random rnd) async {
    final totalCells = board.size * board.size;
    List<GridPos> path = [];
    Set<String> visited = {};
    
    List<GridPos> starts = [];
    for (int i = 0; i < board.size; i++) {
      starts.add(GridPos(i, 0));
      starts.add(GridPos(i, board.size - 1));
      starts.add(GridPos(0, i));
      starts.add(GridPos(board.size - 1, i));
    }
    starts.shuffle(rnd);
    
    GridPos start = starts.first;

    bool solve(GridPos current) {
      path.add(current);
      visited.add('\${current.x},\${current.y}');

      if (path.length == totalCells) {
        return true;
      }

      List<GridPos> neighbors = board.getAdjacent(current)
          .where((p) => !visited.contains('\${p.x},\${p.y}') && !board.hasWall(current, p))
          .toList();

      // Warnsdorff's heuristic + Random jitter for variance
      neighbors.sort((a, b) {
        int aMoves = board.getAdjacent(a).where((p) => !visited.contains('\${p.x},\${p.y}') && !board.hasWall(a, p)).length;
        int bMoves = board.getAdjacent(b).where((p) => !visited.contains('\${p.x},\${p.y}') && !board.hasWall(b, p)).length;
        // Jitter to generate DIFFERENT paths across the loop
        double aScore = aMoves + (rnd.nextDouble() * 0.4);
        double bScore = bMoves + (rnd.nextDouble() * 0.4);
        return aScore.compareTo(bScore);
      });

      for (final next in neighbors) {
        if (solve(next)) {
          return true;
        }
      }

      path.removeLast();
      visited.remove('\${current.x},\${current.y}');
      return false;
    }

    if (solve(start)) return path;
    return [];
  }
}
