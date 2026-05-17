#include "PuzzleGenerator.h"
#include <random>
#include <algorithm>

PuzzleData PuzzleGenerator::Generate(Difficulty diff) {
    int size = 5;
    if (diff == Difficulty::INTERMEDIATE) size = 7;
    if (diff == Difficulty::EXPERT) size = 9;

    while (true) {
        auto board = std::make_unique<Board>(size);
        Path solution;
        if (TryGenerate(*board, solution)) {
            return {std::move(board), solution};
        }
    }
}

bool PuzzleGenerator::DFS(Board& board, GridPos curr, std::vector<GridPos>& currentPath, int targetLen, std::default_random_engine& rng) {
    if (currentPath.size() == (size_t)targetLen) return true;

    std::vector<GridPos> adj = board.GetAdjacent(curr);
    std::shuffle(adj.begin(), adj.end(), rng);

    for (auto n : adj) {
        if (std::find(currentPath.begin(), currentPath.end(), n) == currentPath.end()) {
            currentPath.push_back(n);
            if (DFS(board, n, currentPath, targetLen, rng)) return true;
            currentPath.pop_back();
        }
    }
    return false;
}

bool PuzzleGenerator::TryGenerate(Board& board, Path& outSolution) {
    int size = board.GetSize();
    int targetLen = size * size;
    
    std::vector<GridPos> emptyCells;
    for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
            emptyCells.push_back({x, y});
        }
    }

    auto rng = std::default_random_engine(GetRandomValue(0, 999999));
    std::shuffle(emptyCells.begin(), emptyCells.end(), rng);

    std::vector<GridPos> path;
    path.push_back(emptyCells[0]);

    if (DFS(board, emptyCells[0], path, targetLen, rng)) {
        int k = (size == 5) ? 5 : ((size == 7) ? 7 : 9);
        int step = (targetLen - 1) / (k - 1);
        
        Color baseColor = Color{40, 45, 55, 255};
        
        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                board.ClearTile({x, y});
            }
        }
        
        for (int i = 0; i < k; i++) {
            int index = (i == k - 1) ? (targetLen - 1) : (i * step);
            board.SetNode(path[index], i + 1, baseColor);
        }
        
        board.SetTotalNodes(k);
        
        outSolution.points = path;
        outSolution.color = Color{200, 255, 255, 255};
        return true;
    }

    return false;
}
