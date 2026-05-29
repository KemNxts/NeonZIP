import 'dart:math';
import 'dart:io';

class GridPos {
  final int x;
  final int y;
  GridPos(this.x, this.y);
  @override
  String toString() => '$x,$y';
}

Future<String> generateLevelCategoryFast(String name, int size, int count) async {
  StringBuffer sb = StringBuffer();
  sb.writeln('  static final Map<int, List<String>> $name = {');
  
  for (int levelId = 1; levelId <= count; levelId++) {
    final rnd = Random(levelId * 1000 + size);
    
    // We will generate a random self-avoiding walk.
    // If it gets stuck, and length is > threshold, we accept it.
    // The unvisited cells become 'X' (walls).
    
    int threshold = (size * size) - (size == 9 ? 6 : (size == 7 ? 4 : (levelId > 30 ? 2 : 0)));
    if (size == 5 && levelId <= 30) threshold = 25;
    if (size == 7 && levelId <= 15) threshold = 49;
    
    List<GridPos> bestPath = [];
    
    int attempts = 0;
    while (bestPath.length < threshold && attempts < 2000) {
      attempts++;
      List<GridPos> path = [];
      Set<String> visited = {};
      
      // start at a corner or edge
      GridPos current = GridPos(rnd.nextInt(size), rnd.nextInt(size));
      if (size > 5) {
        if (rnd.nextBool()) current = GridPos(0, rnd.nextInt(size));
        else current = GridPos(rnd.nextInt(size), 0);
      }
      
      path.add(current);
      visited.add(current.toString());
      
      while (true) {
        List<GridPos> neighbors = [];
        if (current.x > 0) neighbors.add(GridPos(current.x - 1, current.y));
        if (current.x < size - 1) neighbors.add(GridPos(current.x + 1, current.y));
        if (current.y > 0) neighbors.add(GridPos(current.x, current.y - 1));
        if (current.y < size - 1) neighbors.add(GridPos(current.x, current.y + 1));
        
        neighbors.removeWhere((p) => visited.contains(p.toString()));
        if (neighbors.isEmpty) break; // Dead end
        
        // Pick random neighbor, with a slight preference to keep moving in same direction to create lines
        GridPos next = neighbors[rnd.nextInt(neighbors.length)];
        if (path.length > 1) {
          GridPos prev = path[path.length - 2];
          int dx = current.x - prev.x;
          int dy = current.y - prev.y;
          GridPos straight = GridPos(current.x + dx, current.y + dy);
          if (neighbors.any((p) => p.x == straight.x && p.y == straight.y)) {
             if (rnd.nextDouble() < 0.6) { // 60% chance to go straight
               next = straight;
             }
          }
        }
        
        current = next;
        path.add(current);
        visited.add(current.toString());
      }
      
      if (path.length > bestPath.length) {
        bestPath = path;
      }
      if (bestPath.length == size * size) break; // Perfect
    }
    
    List<GridPos> path = bestPath;
    
    double progress = ((levelId - 1) / 99.0).clamp(0.0, 1.0);
    double revealPercent = 0.40 - (progress * 0.35);
    if (size == 7) revealPercent = 0.20 - (progress * 0.15);
    if (size == 9) revealPercent = 0.10 - (progress * 0.05);
    
    int nodeCount = max(3, (path.length * revealPercent).ceil());
    
    // Select malicious hints
    List<int> indices = [0, path.length - 1];
    int needed = nodeCount - 2;
    if (needed > 0) {
      List<Map<String, dynamic>> nodeScores = [];
      for (int i = 1; i < path.length - 1; i++) {
        GridPos prev = path[i - 1];
        GridPos curr = path[i];
        GridPos next = path[i + 1];
        bool isCorner = (prev.y == curr.y) != (curr.y == next.y);
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
    }
    
    List<List<String>> grid = List.generate(size, (_) => List.filled(size, '.'));
    
    // Mark unvisited as X
    Set<String> visitedSet = path.map((p) => p.toString()).toSet();
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (!visitedSet.contains('$x,$y')) {
          grid[y][x] = 'X';
        }
      }
    }
    
    // Set hints
    for (int i = 0; i < indices.length; i++) {
      GridPos p = path[indices[i]];
      grid[p.y][p.x] = '${i + 1}';
    }
    
    sb.writeln('    $levelId: [');
    for (int y = 0; y < size; y++) {
      String row = grid[y].join(' ');
      if (y == size - 1) {
        sb.writeln('      "$row"');
      } else {
        sb.writeln('      "$row",');
      }
    }
    if (levelId == count) {
      sb.writeln('    ]');
    } else {
      sb.writeln('    ],');
    }
  }
  sb.writeln('  };');
  return sb.toString();
}

void main() async {
  String out = '''import '../models/grid_pos.dart';

class CustomLevels {
  // Add your custom levels here. The key is the level ID.
  // '.' is an empty walkable cell.
  // 'X' is a wall (blocked cell).
  // Numbers '1', '2', '3'... are the required hints in sequential order.
''';

  out += await generateLevelCategoryFast('beginner', 5, 100);
  out += '\n';
  out += await generateLevelCategoryFast('medium', 7, 100);
  out += '\n';
  out += await generateLevelCategoryFast('hard', 9, 100);
  
  out += '''
  /// Parses the visual grid and generates the string format that LevelManager expects
  static String generateLevelString(List<String> gridStr) {
    int size = gridStr.length;
    Map<int, GridPos> hints = {};
    Set<String> blocked = {};
    int emptyCount = 0;

    for (int y = 0; y < size; y++) {
      List<String> row = gridStr[y].trim().split(RegExp(r'\\s+'));
      for (int x = 0; x < size; x++) {
        if (x >= row.length) continue;
        String cell = row[x];
        if (cell == 'X' || cell == 'x') {
          blocked.add('\$x,\$y');
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

    List<GridPos> path = [];
    Set<String> visited = {};
    List<GridPos> bestPath = [];

    bool solve(GridPos current, int nextExpectedHint) {
      path.add(current);
      visited.add('\${current.x},\${current.y}');

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
          path.removeLast();
          visited.remove('\${current.x},\${current.y}');
          return false;
        }
        if (hintVal == expected) {
          expected++;
        }
      }

      if (path.length == emptyCount) {
        if (expected > maxSeq) {
          bestPath = List.from(path);
          return true;
        }
      }

      List<GridPos> neighbors = [
        GridPos(current.x, current.y - 1),
        GridPos(current.x, current.y + 1),
        GridPos(current.x - 1, current.y),
        GridPos(current.x + 1, current.y),
      ];

      for (var n in neighbors) {
        if (n.x >= 0 && n.x < size && n.y >= 0 && n.y < size) {
          if (!blocked.contains('\${n.x},\${n.y}') && !visited.contains('\${n.x},\${n.y}')) {
            if (solve(n, expected)) return true;
          }
        }
      }

      path.removeLast();
      visited.remove('\${current.x},\${current.y}');
      return false;
    }

    solve(hints[1]!, 2);

    if (bestPath.isEmpty) {
      throw Exception("Could not find a valid solution path");
    }

    StringBuffer sb = StringBuffer();
    sb.writeln('[Header]');
    sb.writeln('Size=\$size');
    sb.writeln('TotalNodes=\${hints.length}');
    sb.writeln();
    
    sb.writeln('[Nodes]');
    var sortedHints = hints.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    for (var hint in sortedHints) {
      sb.writeln('\${hint.key} \${hint.value.x} \${hint.value.y}');
    }
    sb.writeln();

    if (blocked.isNotEmpty) {
      sb.writeln('[Blocked]');
      for (var b in blocked) {
        var parts = b.split(',');
        sb.writeln('\${parts[0]} \${parts[1]}');
      }
      sb.writeln();
    }

    sb.writeln('[Solution]');
    for (var p in bestPath) {
      sb.writeln('\${p.x} \${p.y}');
    }

    return sb.toString();
  }
}
''';

  File('lib/data/custom_levels.dart').writeAsStringSync(out);
  print("Done generating 300 levels!");
}
