import 'package:flutter/material.dart';

enum TileType { empty, node, path }

class Tile {
  TileType type;
  int sequenceNum;
  Color color;
  bool isError;

  Tile({
    this.type = TileType.empty,
    this.sequenceNum = 0,
    this.color = Colors.transparent,
    this.isError = false,
  });

  Tile copyWith({
    TileType? type,
    int? sequenceNum,
    Color? color,
    bool? isError,
  }) {
    return Tile(
      type: type ?? this.type,
      sequenceNum: sequenceNum ?? this.sequenceNum,
      color: color ?? this.color,
      isError: isError ?? this.isError,
    );
  }
}
