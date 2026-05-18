import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board.dart';
import '../models/difficulty.dart';
import '../models/grid_pos.dart';
import '../models/puzzle_data.dart';
import '../models/player_path.dart';
import 'puzzle_generator.dart';

class LevelManager {
  Map<Difficulty, int> maxUnlocked = {
    Difficulty.beginner: 1,
    Difficulty.intermediate: 1,
    Difficulty.expert: 1,
  };
  int currentLevelId = 1;

  Future<void> init() async {
    await loadSaveData();
  }

  Future<void> loadSaveData() async {
    final prefs = await SharedPreferences.getInstance();
    maxUnlocked[Difficulty.beginner] =
        prefs.getInt('maxUnlocked_beginner') ?? 1;
    maxUnlocked[Difficulty.intermediate] =
        prefs.getInt('maxUnlocked_intermediate') ?? 1;
    maxUnlocked[Difficulty.expert] = prefs.getInt('maxUnlocked_expert') ?? 1;
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'maxUnlocked_beginner',
      maxUnlocked[Difficulty.beginner]!,
    );
    await prefs.setInt(
      'maxUnlocked_intermediate',
      maxUnlocked[Difficulty.intermediate]!,
    );
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
    String folder = _getDiffString(diff);
    int count = 0;
    while (true) {
      try {
        await rootBundle.loadString(
          'assets/levels/$folder/level_${count + 1}.level',
        );
        count++;
      } catch (e) {
        break;
      }
    }
    return count > 0 ? count : 1;
  }

  String _getDiffString(Difficulty diff) {
    if (diff == Difficulty.intermediate) return 'intermediate';
    if (diff == Difficulty.expert) return 'expert';
    return 'beginner';
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
      // Fallback to generator
      currentLevelId = levelId;
      return PuzzleGenerator.generate(diff);
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
