import '../models/grid_pos.dart';

class CustomLevels {
  // Add your custom levels here. The key is the level ID.
  // '.' is an empty walkable cell.
  // 'X' is a wall (blocked cell).
  // Numbers '1', '2', '3'... are the required hints in sequential order.
  static final Map<int, List<String>> beginner = {
    // Override level 5 with a custom layout

    1: [
      "1 . . . .",
      ". . . . .",
      ". . . . .",
      ". . . . .",
      "2 . . . 3"
    ],
    5: [
      ". . 1 . .",
      ". X . . .",
      ". . . 2 .",
      ". . . . .",
      "3 . . X ."
    ]
  };

  /// Parses the visual grid and generates the string format that LevelManager expects
  static String generateLevelString(List<String> gridStr) {
    int size = gridStr.length;
    Map<int, GridPos> hints = {};
    Set<String> blocked = {};
    int emptyCount = 0;

    for (int y = 0; y < size; y++) {
      // Split by spaces, allowing multiple spaces for visual alignment
      List<String> row = gridStr[y].trim().split(RegExp(r'\s+'));
      for (int x = 0; x < size; x++) {
        if (x >= row.length) continue;
        String cell = row[x];
        if (cell == 'X' || cell == 'x') {
          blocked.add('$x,$y');
        } else {
          emptyCount++;
          if (cell != '.') {
            int? seq = int.tryParse(cell);
            if (seq != null) {
              hints[seq] = GridPos(x, y);
            }
          }
        }
      }
    }

    if (!hints.containsKey(1)) {
      throw Exception("Custom level must have a starting node '1'");
    }

    int maxSeq = hints.keys.reduce((a, b) => a > b ? a : b);

    // DFS to find the required Hamiltonian path
    List<GridPos> path = [];
    Set<String> visited = {};
    List<GridPos> bestPath = [];

    bool solve(GridPos current, int nextExpectedHint) {
      path.add(current);
      visited.add('${current.x},${current.y}');

      bool isHint = false;
      int hintVal = -1;
      for (var entry in hints.entries) {
        if (entry.value.x == current.x && entry.value.y == current.y) {
          isHint = true;
          hintVal = entry.key;
          break;
        }
      }

      int expected = nextExpectedHint;
      if (isHint) {
        if (hintVal != 1 && hintVal != expected) {
          // Hit a hint out of order
          path.removeLast();
          visited.remove('${current.x},${current.y}');
          return false;
        }
        if (hintVal == expected) {
          expected++;
        }
      }

      if (path.length == emptyCount) {
        if (expected > maxSeq) { // All hints found
          bestPath = List.from(path);
          return true;
        }
      }

      // Explore neighbors
      List<GridPos> neighbors = [
        GridPos(current.x, current.y - 1),
        GridPos(current.x, current.y + 1),
        GridPos(current.x - 1, current.y),
        GridPos(current.x + 1, current.y),
      ];

      for (var n in neighbors) {
        if (n.x >= 0 && n.x < size && n.y >= 0 && n.y < size) {
          if (!blocked.contains('${n.x},${n.y}') && !visited.contains('${n.x},${n.y}')) {
            if (solve(n, expected)) return true;
          }
        }
      }

      path.removeLast();
      visited.remove('${current.x},${current.y}');
      return false;
    }

    // Node 1 is always the starting point
    solve(hints[1]!, 2);

    if (bestPath.isEmpty) {
      throw Exception("Could not find a valid solution path for this custom level grid. Please check your wall placement and ensure all cells are reachable.");
    }

    // Generate output string matching [Header], [Nodes], [Blocked], [Solution]
    StringBuffer sb = StringBuffer();
    sb.writeln('[Header]');
    sb.writeln('Size=$size');
    sb.writeln('TotalNodes=${hints.length}');
    sb.writeln();
    
    sb.writeln('[Nodes]');
    var sortedHints = hints.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    for (var hint in sortedHints) {
      sb.writeln('${hint.key} ${hint.value.x} ${hint.value.y}');
    }
    sb.writeln();

    if (blocked.isNotEmpty) {
      sb.writeln('[Blocked]');
      for (var b in blocked) {
        var parts = b.split(',');
        sb.writeln('${parts[0]} ${parts[1]}');
      }
      sb.writeln();
    }

    sb.writeln('[Solution]');
    for (var p in bestPath) {
      sb.writeln('${p.x} ${p.y}');
    }

    return sb.toString();
  }
}
