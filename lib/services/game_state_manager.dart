import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/board.dart';
import '../models/difficulty.dart';
import '../models/grid_pos.dart';
import '../models/player_path.dart';
import '../models/puzzle_data.dart';
import '../models/tile.dart';
import 'level_manager.dart';
import 'procedural_audio_engine.dart';

enum GameState { menu, playing, levelComplete }

class GameStateManager extends ChangeNotifier {
  final LevelManager levelManager;
  final ProceduralAudioEngine audioEngine = ProceduralAudioEngine();

  Board? board;
  PlayerPath playerPath = PlayerPath();
  PlayerPath? solution;

  GameState state = GameState.menu;
  Difficulty currentDifficulty = Difficulty.beginner;
  int movesCounter = 0;

  bool isDrawing = false;
  bool isAnimatingBlast = false;
  bool isAnimatingExtension = false;
  bool isCompleting = false;
  bool isGrandFinale = false;
  GridPos? lastValidPos;

  // UI Event Triggers (Phase 2 Decoupling)
  final ValueNotifier<int> invalidMoveTrigger = ValueNotifier<int>(0);


  GameStateManager(this.levelManager);

  Future<void> init() async {
    await levelManager.init();
    await audioEngine.init();
    notifyListeners();
  }

  @override
  void dispose() {
    audioEngine.dispose();
    super.dispose();
  }

  Future<void> generateLevel(Difficulty diff) async {
    int maxUnlocked = levelManager.getMaxUnlockedLevel(diff);
    await loadSpecificLevel(diff, maxUnlocked);
  }

  Future<void> loadSpecificLevel(Difficulty diff, int id) async {
    currentDifficulty = diff;
    try {
      PuzzleData data = await levelManager.loadLevel(diff, id);
      board = data.board;
      solution = data.solution;
    } catch (e) {
      debugPrint('CRITICAL: loadLevel threw an unhandled exception: $e');
      // Instant Fallback to prevent UI lock
      board = Board(5);
      board!.totalNodes = 1;
      board!.setNode(GridPos(0, 0), 1, Colors.red);
      solution = PlayerPath();
    } finally {
      // Phase 3: State Machine Sanitation 
      // Guarantee touch screens instantly reactivate even if an Isolate crashes
      playerPath = PlayerPath(color: const Color.fromRGBO(200, 255, 255, 1.0));
      isDrawing = false;
      isCompleting = false;
      isGrandFinale = false;
      isAnimatingBlast = false;
      isAnimatingExtension = false;
      lastValidPos = null;
      state = GameState.playing;
      movesCounter = 0;
      notifyListeners();
    }
  }

  void resetLevel() {
    playerPath.points.clear();
    isDrawing = false;
    movesCounter = 0;
    notifyListeners();
  }

  void undoLastPoint() {
    if (playerPath.points.isNotEmpty) {
      playerPath.points.removeLast();
      if (playerPath.points.isNotEmpty) {
        lastValidPos = playerPath.points.last;
        audioEngine.playPathExtensionNote(playerPath.points.length);
      } else {
        lastValidPos = null;
        isDrawing = false;
      }
      notifyListeners();
    }
  }

  void startPath(GridPos pos) {
    if (board == null) return;
    movesCounter++;
    isDrawing = true;
    playerPath = PlayerPath(color: const Color.fromRGBO(200, 255, 255, 1.0));
    playerPath.addPoint(pos);
    lastValidPos = pos;
    audioEngine.playDragStartClick();
    notifyListeners();
  }

  void addPathPoint(GridPos pos) {
    if (board == null) return;

    if (playerPath.points.length > 1 &&
        playerPath.points[playerPath.points.length - 2] == pos) {
      playerPath.points.removeLast();
      lastValidPos = pos;
      audioEngine.playPathExtensionNote(playerPath.points.length);
      notifyListeners();
      return;
    }

    if (playerPath.contains(pos)) return;

    int expectedNext = 2;
    for (var p in playerPath.points) {
      var tile = board!.getTile(p);
      if (tile.type == TileType.node) {
        expectedNext = tile.sequenceNum + 1;
      }
    }

    var t = board!.getTile(pos);
    if (t.type == TileType.node) {
      if (t.sequenceNum != expectedNext) {
        invalidMoveTrigger.value++;
        HapticFeedback.vibrate();
        audioEngine.playErrorTone();
        return;
      }
    }


    playerPath.addPoint(pos);
    lastValidPos = pos;
    HapticFeedback.selectionClick();
    audioEngine.playPathExtensionNote(playerPath.points.length);
    notifyListeners();

    if (t.type == TileType.node && t.sequenceNum == board!.totalNodes) {
      endPath();
    }
  }

  bool isPathFullyValid() {
    if (board == null) return false;
    final points = playerPath.points;
    final int expectedLength = board!.walkableCellCount;

    // 1. Check exact board coverage length
    if (points.length != expectedLength) return false;

    // 2. Check path start is Node 1
    if (points.isEmpty) return false;
    final startTile = board!.getTile(points.first);
    if (startTile.type != TileType.node || startTile.sequenceNum != 1) {
      return false;
    }

    // 3. Check path end is the last Node
    final endTile = board!.getTile(points.last);
    if (endTile.type != TileType.node || endTile.sequenceNum != board!.totalNodes) {
      return false;
    }

    // 4. Check continuity and uniqueness
    final Set<GridPos> visited = {};
    for (int i = 0; i < points.length; i++) {
      final pos = points[i];
      
      // Uniqueness
      if (!visited.add(pos)) return false;

      // Continuity
      if (i > 0) {
        final prev = points[i - 1];
        if (!board!.isAdjacent(prev, pos)) return false;
      }
    }

    // 5. Check exact sequential order of all nodes
    int nextNodeExpected = 1;
    for (final pos in points) {
      final tile = board!.getTile(pos);
      if (tile.type == TileType.node) {
        if (tile.sequenceNum != nextNodeExpected) {
          return false;
        }
        nextNodeExpected++;
      }
    }

    // Must have visited all nodes up to totalNodes
    if (nextNodeExpected - 1 != board!.totalNodes) {
      return false;
    }

    return true;
  }

  Future<void> endPath() async {
    isDrawing = false;
    if (board == null || isCompleting) return;

    if (isPathFullyValid()) {
      isCompleting = true;
      HapticFeedback.heavyImpact();
      audioEngine.playLevelCompleteFanfare();
      notifyListeners(); // Render the completed path
      
      await Future.delayed(const Duration(milliseconds: 500)); // Cinematic pause
      
      isAnimatingBlast = true;
      notifyListeners();
      
      // Wait for the blast wave to finish (e.g. 1.2s)
      await Future.delayed(const Duration(milliseconds: 1200));
      
      isAnimatingBlast = false;
      state = GameState.levelComplete;
      isCompleting = false;
      levelManager.unlockNextLevel(currentDifficulty);
      if (currentDifficulty == Difficulty.hard && levelManager.currentLevelId >= 100) {
        isGrandFinale = true;
      }
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  Future<bool> applyHint() async {
    if (solution == null || board == null || isAnimatingExtension) return false;

    // If path is already longer than or equal to solution, check if it's perfectly matched.
    if (playerPath.points.length >= solution!.points.length) {
      bool perfect = true;
      for (int i = 0; i < solution!.points.length; i++) {
        if (playerPath.points[i] != solution!.points[i]) {
          perfect = false;
          break;
        }
      }
      if (perfect) return false;
    }

    // 1. The Deviation Deep-Scan
    int mismatchIndex = -1;
    for (int i = 0; i < playerPath.points.length; i++) {
      if (i >= solution!.points.length || playerPath.points[i] != solution!.points[i]) {
        mismatchIndex = i;
        break;
      }
    }

    // 2. Surgical Backtracking
    if (mismatchIndex != -1) {
      playerPath.points = playerPath.points.sublist(0, mismatchIndex);
      if (playerPath.points.isNotEmpty) {
        lastValidPos = playerPath.points.last;
      } else {
        lastValidPos = null;
      }
      notifyListeners();
      // Brief pause to let player see the invalid path vanish before extending
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // 3. Procedural Line Extension (Add up to 3 correct steps)
    int startIndex = playerPath.points.length;
    int targetSteps = 3;
    int addedSteps = 0;

    isAnimatingExtension = true;
    notifyListeners();

    for (int i = startIndex; i < solution!.points.length && addedSteps < targetSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      GridPos nextPos = solution!.points[i];
      if (playerPath.points.isEmpty) {
        startPath(nextPos);
      } else {
        addPathPoint(nextPos);
      }
      // Audio Cue for satisfying hint progression
      audioEngine.playPathExtensionNote(playerPath.points.length);
      notifyListeners();
      addedSteps++;
    }

    isAnimatingExtension = false;
    isDrawing = false;
    notifyListeners();
    return addedSteps > 0 || mismatchIndex != -1;
  }

  void handleInput(GridPos gPos) {
    if (board == null || state != GameState.playing || isAnimatingExtension || isCompleting) return;

    if (board!.isValidPos(gPos)) {
      if (playerPath.points.isEmpty) {
        var tile = board!.getTile(gPos);
        if (tile.type == TileType.node && tile.sequenceNum == 1) {
          startPath(gPos);
        }
      } else {
        if (gPos == playerPath.points.last) {
          isDrawing = true;
          lastValidPos = gPos;
        } else if (playerPath.contains(gPos)) {
          playerPath.backtrackTo(gPos);
          isDrawing = true;
          lastValidPos = gPos;
          HapticFeedback.mediumImpact();
          audioEngine.playPathExtensionNote(playerPath.points.length);
          notifyListeners();
        }
      }
    }
  }

  void handleDragUpdate(GridPos gPos) {
    if (board == null || state != GameState.playing || !isDrawing || isAnimatingExtension || isCompleting) return;

    if (board!.isValidPos(gPos) && gPos != lastValidPos) {
      if (lastValidPos != null && board!.isAdjacent(lastValidPos!, gPos)) {
        addPathPoint(gPos);
      }
    }
  }

  void handleDragEnd() {
    if (state == GameState.playing && isDrawing && !isAnimatingExtension && !isCompleting) {
      endPath();
    }
  }

  /// Instantly extends the path from the current tip to [target] along a
  /// straight horizontal or vertical line.
  ///
  /// Returns true if the extension was applied, false if invalid.
  Future<bool> tapExtendPath(GridPos target) async {
    if (board == null || state != GameState.playing || isAnimatingExtension || isCompleting) return false;
    if (playerPath.points.isEmpty) return false;

    final current = playerPath.points.last;
    if (current == target) return false;

    // Must be in same row OR same column.
    final sameCol = current.x == target.x;
    final sameRow = current.y == target.y;
    if (!sameCol && !sameRow) return false;

    // Build the ordered list of cells to traverse (exclusive of current,
    // inclusive of target).
    final cells = <GridPos>[];
    if (sameCol) {
      final step = target.y > current.y ? 1 : -1;
      for (int y = current.y + step;
          step > 0 ? y <= target.y : y >= target.y;
          y += step) {
        cells.add(GridPos(current.x, y));
      }
    } else {
      final step = target.x > current.x ? 1 : -1;
      for (int x = current.x + step;
          step > 0 ? x <= target.x : x >= target.x;
          x += step) {
        cells.add(GridPos(x, current.y));
      }
    }

    final toCommit = <GridPos>[];
    int expectedNext = _expectedNextNode();
    bool hitEndNode = false;
    GridPos previous = current;

    for (final pos in cells) {
      // 0. Stop if blocked by an inner wall
      if (board!.hasWall(previous, pos)) {
        break;
      }

      // 1. Stop if blocked (already visited)
      if (playerPath.contains(pos)) {
        break;
      }

      final tile = board!.getTile(pos);
      if (tile.type == TileType.node) {
        // 2. If it's a node, check sequence
        if (tile.sequenceNum == expectedNext) {
          toCommit.add(pos);
          expectedNext++;
          if (tile.sequenceNum == board!.totalNodes) {
            hitEndNode = true;
          }
          // Stop at the valid node, do not traverse beyond it in a single tap
          break;
        } else {
          // Stop right before the invalid node
          invalidMoveTrigger.value++;
          HapticFeedback.vibrate();
          audioEngine.playErrorTone();
          break;

        }
      } else {
        // Empty cell — safe to add and continue
        toCommit.add(pos);
      }
      previous = pos;
    }

    if (toCommit.isEmpty) return false;

    isAnimatingExtension = true;

    // Commit the valid prefix sequentially with a delay to animate
    for (final pos in toCommit) {
      if (state != GameState.playing) break; // In case game was reset
      playerPath.addPoint(pos);
      lastValidPos = pos;
      HapticFeedback.lightImpact();
      audioEngine.playPathExtensionNote(playerPath.points.length);
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 8));
    }

    isAnimatingExtension = false;

    if (hitEndNode) {
      endPath();
    } else {
      isDrawing = false;
      notifyListeners();
    }

    return true;
  }

  int _expectedNextNode() {
    int next = 2;
    for (final p in playerPath.points) {
      final tile = board!.getTile(p);
      if (tile.type == TileType.node) next = tile.sequenceNum + 1;
    }
    return next;
  }

  void backToMenu() {
    state = GameState.menu;
    notifyListeners();
  }
}
