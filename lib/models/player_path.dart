import 'package:flutter/material.dart';
import 'grid_pos.dart';

class PlayerPath {
  Color color;
  bool completed;
  bool isError;
  List<GridPos> points;

  PlayerPath({
    this.color = Colors.transparent,
    this.completed = false,
    this.isError = false,
    List<GridPos>? points,
  }) : points = points ?? [];

  void addPoint(GridPos pos) {
    points.add(pos);
  }

  void backtrackTo(GridPos pos) {
    int index = points.indexOf(pos);
    if (index != -1) {
      points.removeRange(index + 1, points.length);
    }
  }

  bool contains(GridPos pos) {
    return points.contains(pos);
  }

  PlayerPath clone() {
    return PlayerPath(
      color: color,
      completed: completed,
      isError: isError,
      points: List.from(points),
    );
  }
}
