#include "Board.h"
#include <cmath>

Board::Board(int size) : size(size), totalNodes(0) {
    grid.resize(size, std::vector<Tile>(size));
}

Tile& Board::GetTile(int x, int y) { return grid[y][x]; }
const Tile& Board::GetTile(int x, int y) const { return grid[y][x]; }

Tile& Board::GetTile(GridPos pos) { return grid[pos.y][pos.x]; }
const Tile& Board::GetTile(GridPos pos) const { return grid[pos.y][pos.x]; }

bool Board::IsValidPos(GridPos pos) const {
    return pos.x >= 0 && pos.x < size && pos.y >= 0 && pos.y < size;
}

bool Board::IsAdjacent(GridPos a, GridPos b) const {
    return (std::abs(a.x - b.x) == 1 && a.y == b.y) || 
           (std::abs(a.y - b.y) == 1 && a.x == b.x);
}

std::vector<GridPos> Board::GetAdjacent(GridPos pos) const {
    std::vector<GridPos> adj;
    GridPos dirs[] = {{0, -1}, {0, 1}, {-1, 0}, {1, 0}};
    for (auto d : dirs) {
        GridPos p = {pos.x + d.x, pos.y + d.y};
        if (IsValidPos(p)) {
            adj.push_back(p);
        }
    }
    return adj;
}

void Board::ClearPaths() {
    for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
            if (grid[y][x].type == TileType::PATH) {
                grid[y][x].type = TileType::EMPTY;
                grid[y][x].sequenceNum = 0;
                grid[y][x].color = BLANK;
            }
        }
    }
}

void Board::ResetErrors() {
    for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
            grid[y][x].isError = false;
        }
    }
}

bool Board::IsFull() const {
    for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
            if (grid[y][x].type == TileType::EMPTY) return false;
        }
    }
    return true;
}

void Board::ResetBoard() {
    ClearPaths();
    ResetErrors();
}


void Board::SetNode(GridPos pos, int sequenceNum, Color color) {
    if (IsValidPos(pos)) {
        grid[pos.y][pos.x] = {TileType::NODE, sequenceNum, color, false};
    }
}

void Board::SetPath(GridPos pos, int sequenceNum, Color color) {
    if (IsValidPos(pos)) {
        grid[pos.y][pos.x] = {TileType::PATH, sequenceNum, color, false};
    }
}

void Board::ClearTile(GridPos pos) {
    if (IsValidPos(pos)) {
        grid[pos.y][pos.x] = {TileType::EMPTY, 0, BLANK, false};
    }
}
