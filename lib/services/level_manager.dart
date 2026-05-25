import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board.dart';
import '../models/difficulty.dart';
import '../models/grid_pos.dart';
import '../models/puzzle_data.dart';
import '../models/player_path.dart';
import 'level_generator.dart';

class LevelManager {
  Map<Difficulty, int> maxUnlocked = {
    Difficulty.beginner: 1,
    Difficulty.easy: 1,
    Difficulty.medium: 1,
    Difficulty.hard: 1,
    Difficulty.expert: 1,
  };
  int currentLevelId = 1;
  final LevelGenerator _generator = LevelGenerator();

  Future<void> init() async {
    await loadSaveData();
  }

  Future<void> loadSaveData() async {
    final prefs = await SharedPreferences.getInstance();
    maxUnlocked[Difficulty.beginner] = prefs.getInt('maxUnlocked_beginner') ?? 1;
    maxUnlocked[Difficulty.easy] = prefs.getInt('maxUnlocked_easy') ?? 1;
    maxUnlocked[Difficulty.medium] = prefs.getInt('maxUnlocked_medium') ?? 1;
    maxUnlocked[Difficulty.hard] = prefs.getInt('maxUnlocked_hard') ?? 1;
    maxUnlocked[Difficulty.expert] = prefs.getInt('maxUnlocked_expert') ?? 1;
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxUnlocked_beginner', maxUnlocked[Difficulty.beginner]!);
    await prefs.setInt('maxUnlocked_easy', maxUnlocked[Difficulty.easy]!);
    await prefs.setInt('maxUnlocked_medium', maxUnlocked[Difficulty.medium]!);
    await prefs.setInt('maxUnlocked_hard', maxUnlocked[Difficulty.hard]!);
    await prefs.setInt('maxUnlocked_expert', maxUnlocked[Difficulty.expert]!);
  }

  Future<void> unlockNextLevel(Difficulty diff) async {
    if (currentLevelId == maxUnlocked[diff]) {
      int maxLevels = await getMaxLevels(diff);
      if (maxUnlocked[diff]! < maxLevels) {
        maxUnlocked[diff] = maxUnlocked[diff]! + 1;
        await saveData();
      }
    }
  }

  int getMaxUnlockedLevel(Difficulty diff) {
    return maxUnlocked[diff] ?? 1;
  }

  Future<int> getMaxLevels(Difficulty diff) async {
    return 100; // Scaled to exactly 100 levels per difficulty using the Master Designer procedural generator
  }

  String _getDiffString(Difficulty diff) {
    return diff.name;
  }

  Future<PuzzleData> loadLevel(Difficulty diff, int levelId) async {
    String folder = _getDiffString(diff);
    String path = 'assets/levels/$folder/level_$levelId.level';

    try {
      String fileContent = await rootBundle.loadString(path);
      PuzzleData data = _parseLevelData(fileContent);
      currentLevelId = levelId;
      return data;
    } catch (e) {
      // Fallback to procedural generator
      currentLevelId = levelId;
      return await _generator.generate(diff, levelId);
    }
  }

  PuzzleData _parseLevelData(String content) {
    int size = 5;
    int totalNodes = 5;
    Board? board;
    PlayerPath solution = PlayerPath();
    solution.color = const Color.fromRGBO(200, 255, 255, 1.0);

    String currentSection = 'NONE';
    Color baseColor = const Color.fromRGBO(40, 45, 55, 1.0);

    List<String> lines = content.split('\n');
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line == '[Header]') {
        currentSection = 'HEADER';
        continue;
      }
      if (line == '[Nodes]') {
        currentSection = 'NODES';
        continue;
      }
      if (line == '[Solution]') {
        currentSection = 'SOLUTION';
        continue;
      }

      if (currentSection == 'HEADER') {
        if (line.startsWith('Size=')) {
          size = int.parse(line.substring(5));
          board = Board(size);
        }
        if (line.startsWith('TotalNodes=')) {
          totalNodes = int.parse(line.substring(11));
        }
      } else if (currentSection == 'NODES') {
        var parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          int seq = int.parse(parts[0]);
          int x = int.parse(parts[1]);
          int y = int.parse(parts[2]);
          board?.setNode(GridPos(x, y), seq, baseColor);
        }
      } else if (currentSection == 'SOLUTION') {
        var parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          int x = int.parse(parts[0]);
          int y = int.parse(parts[1]);
          solution.addPoint(GridPos(x, y));
        }
      }
    }

    board ??= Board(size);
    board.totalNodes = totalNodes;

    return PuzzleData(board: board, solution: solution);
  }
}
