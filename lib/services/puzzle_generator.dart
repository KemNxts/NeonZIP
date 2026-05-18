import 'dart:math';
import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/difficulty.dart';
import '../models/grid_pos.dart';
import '../models/player_path.dart';
import '../models/puzzle_data.dart';

class PuzzleGenerator {
  static PuzzleData generate(Difficulty diff) {
    int size = 5;
    if (diff == Difficulty.intermediate) size = 7;
    if (diff == Difficulty.expert) size = 9;

    while (true) {
      Board board = Board(size);
      PlayerPath solution = PlayerPath();
      if (_tryGenerate(board, solution)) {
        return PuzzleData(board: board, solution: solution);
      }
    }
  }

  static bool _tryGenerate(Board board, PlayerPath outSolution) {
    int size = board.size;
    int targetLen = size * size;

    List<GridPos> emptyCells = [];
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        emptyCells.add(GridPos(x, y));
      }
    }

    final random = Random();
    emptyCells.shuffle(random);

    List<GridPos> path = [emptyCells[0]];

    if (_dfs(board, emptyCells[0], path, targetLen, random)) {
      int k = (size == 5) ? 5 : ((size == 7) ? 7 : 9);
      int step = (targetLen - 1) ~/ (k - 1);

      Color baseColor = const Color.fromRGBO(40, 45, 55, 1.0);

      for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
          board.clearTile(GridPos(x, y));
        }
      }

      for (int i = 0; i < k; i++) {
        int index = (i == k - 1) ? (targetLen - 1) : (i * step);
        board.setNode(path[index], i + 1, baseColor);
      }

      board.totalNodes = k;
      outSolution.points = path;
      outSolution.color = const Color.fromRGBO(200, 255, 255, 1.0);
      return true;
    }

    return false;
  }

  static bool _dfs(
    Board board,
    GridPos curr,
    List<GridPos> currentPath,
    int targetLen,
    Random random,
  ) {
    if (currentPath.length == targetLen) return true;

    List<GridPos> adj = board.getAdjacent(curr);
    adj.shuffle(random);

    for (var n in adj) {
      if (!currentPath.contains(n)) {
        currentPath.add(n);
        if (_dfs(board, n, currentPath, targetLen, random)) return true;
        currentPath.removeLast();
      }
    }
    return false;
  }
}
