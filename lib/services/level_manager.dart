import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board.dart';
import '../models/difficulty.dart';
import '../models/grid_pos.dart';
import '../models/puzzle_data.dart';
import '../models/player_path.dart';
import '../data/custom_levels.dart';
import 'level_generator.dart';

class LevelManager {
  Map<Difficulty, int> maxUnlocked = {
    Difficulty.beginner: 1,
    Difficulty.medium: 1,
    Difficulty.hard: 1,
  };
  int currentLevelId = 1;
  final LevelGenerator _generator = LevelGenerator();

  Future<void> init() async {
    await loadSaveData();
  }

  Future<void> loadSaveData() async {
    final prefs = await SharedPreferences.getInstance();
    maxUnlocked[Difficulty.beginner] = prefs.getInt('maxUnlocked_beginner') ?? 1;
    maxUnlocked[Difficulty.medium] = prefs.getInt('maxUnlocked_medium') ?? 1;
    maxUnlocked[Difficulty.hard] = prefs.getInt('maxUnlocked_hard') ?? 1;
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxUnlocked_beginner', maxUnlocked[Difficulty.beginner]!);
    await prefs.setInt('maxUnlocked_medium', maxUnlocked[Difficulty.medium]!);
    await prefs.setInt('maxUnlocked_hard', maxUnlocked[Difficulty.hard]!);
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
    // Phase 1: Tactical Bypass for Hard Mode to prevent deadlocks
    if (diff == Difficulty.hard) {
      currentLevelId = levelId;
      return await compute(LevelGenerator.generateIsolate, {'diff': diff, 'levelId': levelId});
    }

    // Priority 1: Check if the requested level ID exists in CustomLevels
    Map<int, List<String>>? customMap;
    switch (diff) {
      case Difficulty.beginner:
        customMap = CustomLevels.beginner;
        break;
      case Difficulty.medium:
        customMap = CustomLevels.medium;
        break;
      case Difficulty.hard:
        customMap = CustomLevels.hard;
        break;
      default:
        customMap = null;
    }

    if (customMap != null && customMap.containsKey(levelId)) {
      try {
        // Phase 2: Offload heavy CustomLevels DFS verification to a background isolate with 200ms watchdog
        String customContent = await compute(CustomLevels.generateLevelString, customMap[levelId]!)
            .timeout(const Duration(milliseconds: 200));
        PuzzleData data = await compute(LevelManager.parseLevelDataIsolate, customContent);
        currentLevelId = levelId;
        return data;
      } catch (e) {
        debugPrint('\n⚠️ FALLBACK TRIGGERED: Custom Level $levelId for ${diff.name} failed to load.');
        debugPrint('Reason: $e\n');
        // Fallthrough to Priority 2
      }
    }

    // Priority 2: Fall back gracefully to loading the default .level asset file
    String folder = _getDiffString(diff);
    String path = 'assets/levels/$folder/level_$levelId.level';

    try {
      String fileContent = await rootBundle.loadString(path);
      PuzzleData data = await compute(LevelManager.parseLevelDataIsolate, fileContent);
      currentLevelId = levelId;
      return data;
    } catch (e) {
      // Priority 3: Fallback to procedural generator (Offloaded to isolate with watchdog)
      currentLevelId = levelId;
      try {
        return await compute(LevelGenerator.generateIsolate, {'diff': diff, 'levelId': levelId})
            .timeout(const Duration(milliseconds: 200));
      } catch (e2) {
        debugPrint('\n🛑 WATCHDOG TRIGGERED: Procedural Generation Timed Out! Serving Fallback Grid.\n');
        // Ultimate Instant Fallback: Provide a valid empty 5x5 board instantly so UI never freezes
        Board safeBoard = Board(5);
        safeBoard.totalNodes = 2;
        safeBoard.setNode(GridPos(0, 0), 1, Colors.blue);
        safeBoard.setNode(GridPos(4, 4), 2, Colors.purple);
        
        PlayerPath safeSolution = PlayerPath();
        for (int i = 0; i < 5; i++) safeSolution.addPoint(GridPos(0, i));
        for (int i = 1; i < 5; i++) safeSolution.addPoint(GridPos(i, 4));
        
        return PuzzleData(board: safeBoard, solution: safeSolution);
      }
    }
  }

  static PuzzleData parseLevelDataIsolate(String content) {
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
      if (line == '[Blocked]') {
        currentSection = 'BLOCKED';
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
      } else if (currentSection == 'BLOCKED') {
        var parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          int x = int.parse(parts[0]);
          int y = int.parse(parts[1]);
          board?.addBlocked(GridPos(x, y));
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
