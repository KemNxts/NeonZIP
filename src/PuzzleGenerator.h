#pragma once
#include "Board.h"
#include "Path.h"
#include <memory>
#include <random>
#include <vector>

enum class Difficulty {
    BEGINNER,   
    INTERMEDIATE, 
    EXPERT    
};

struct PuzzleData {
    std::unique_ptr<Board> board;
    Path solution;
};

class PuzzleGenerator {
public:
    static PuzzleData Generate(Difficulty diff);
private:
    static bool TryGenerate(Board& board, Path& outSolution);
    static bool DFS(Board& board, GridPos curr, std::vector<GridPos>& currentPath, int targetLen, std::default_random_engine& rng);
};
