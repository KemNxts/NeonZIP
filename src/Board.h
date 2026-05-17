#pragma once
#include <vector>
#include <raylib.h>

struct GridPos {
    int x, y;
    bool operator==(const GridPos& other) const { return x == other.x && y == other.y; }
    bool operator!=(const GridPos& other) const { return !(*this == other); }
};

enum class TileType {
    EMPTY,
    NODE,
    PATH
};

struct Tile {
    TileType type = TileType::EMPTY;
    int sequenceNum = 0;
    Color color = BLANK;
    bool isError = false;
};

class Board {
public:
    Board(int size);

    int GetSize() const { return size; }
    
    Tile& GetTile(int x, int y);
    const Tile& GetTile(int x, int y) const;
    Tile& GetTile(GridPos pos);
    const Tile& GetTile(GridPos pos) const;

    bool IsValidPos(GridPos pos) const;
    bool IsAdjacent(GridPos a, GridPos b) const;
    std::vector<GridPos> GetAdjacent(GridPos pos) const;

    bool IsFull() const;
    void ResetBoard();

    void ClearPaths();
    void ResetErrors();
    
    void SetNode(GridPos pos, int sequenceNum, Color color);
    void SetPath(GridPos pos, int sequenceNum, Color color);
    void ClearTile(GridPos pos);

    int GetTotalNodes() const { return totalNodes; }
    void SetTotalNodes(int nodes) { totalNodes = nodes; }

    const std::vector<std::vector<Tile>>& GetGrid() const { return grid; }

private:
    int size;
    int totalNodes;
    std::vector<std::vector<Tile>> grid;
};
