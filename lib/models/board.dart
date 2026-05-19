import 'package:flutter/material.dart';
import 'grid_pos.dart';
import 'tile.dart';

class Board {
  final int size;
  int totalNodes;
  late List<List<Tile>> grid;

  // Stores walls between adjacent cells. Key format: "minX,minY-maxX,maxY"
  final Set<String> walls = {};

  Board(this.size) : totalNodes = 0 {
    grid = List.generate(size, (_) => List.generate(size, (_) => Tile()));
  }

  String _wallKey(GridPos a, GridPos b) {
    if (a.x < b.x || (a.x == b.x && a.y < b.y)) {
      return '${a.x},${a.y}-${b.x},${b.y}';
    } else {
      return '${b.x},${b.y}-${a.x},${a.y}';
    }
  }

  void addWall(GridPos a, GridPos b) {
    if (isValidPos(a) && isValidPos(b)) {
      walls.add(_wallKey(a, b));
    }
  }

  bool hasWall(GridPos a, GridPos b) {
    return walls.contains(_wallKey(a, b));
  }

  Tile getTile(GridPos pos) {
    if (!isValidPos(pos)) return Tile();
    return grid[pos.y][pos.x];
  }

  bool isValidPos(GridPos pos) {
    return pos.x >= 0 && pos.x < size && pos.y >= 0 && pos.y < size;
  }

  /// Checks if two cells are geometrically adjacent AND not separated by a wall.
  bool isAdjacent(GridPos a, GridPos b) {
    bool geomAdj = (a.x == b.x && (a.y - b.y).abs() == 1) ||
        (a.y == b.y && (a.x - b.x).abs() == 1);
    if (!geomAdj) return false;
    return !hasWall(a, b);
  }

  List<GridPos> getAdjacent(GridPos pos) {
    List<GridPos> adj = [];
    final offsets = [
      GridPos(0, -1),
      GridPos(0, 1),
      GridPos(-1, 0),
      GridPos(1, 0),
    ];
    for (var offset in offsets) {
      final newPos = GridPos(pos.x + offset.x, pos.y + offset.y);
      if (isValidPos(newPos)) {
        adj.add(newPos);
      }
    }
    return adj;
  }

  void clearTile(GridPos pos) {
    if (isValidPos(pos)) {
      grid[pos.y][pos.x] = Tile();
    }
  }

  void setNode(GridPos pos, int sequenceNum, Color color) {
    if (isValidPos(pos)) {
      grid[pos.y][pos.x] = Tile(
        type: TileType.node,
        sequenceNum: sequenceNum,
        color: color,
      );
    }
  }
}
