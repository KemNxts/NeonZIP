#pragma once
#include "Board.h"
#include "Path.h"
#include "LevelManager.h"
#include <memory>
#include <vector>

class VFXSystem;

enum class GameState {
    MENU,
    PLAYING,
    LEVEL_COMPLETE
};

class GameManager {
public:
    GameManager(int screenWidth, int screenHeight);
    
    void Update(float dt);
    void SetVFXSystem(VFXSystem* vfxSys) { vfx = vfxSys; }
    void GenerateLevel(Difficulty diff);
    void LoadSpecificLevel(Difficulty diff, int id);
    const LevelManager& GetLevelManager() const { return levelManager; }

    const Board* GetBoard() const { return board.get(); }
    const Path* GetPlayerPath() const { return &playerPath; }
    
    float GetCellSize() const { return cellSize; }
    Vector2 GetGridOffset() const { return gridOffset; }
    GameState GetState() const { return state; }
    Difficulty GetDifficulty() const { return currentDifficulty; }
    int GetMoves() const { return movesCounter; }
    GridPos GetHoveredPos() const { return hoveredPos; }

private:
    Vector2 GridToWorld(GridPos pos) const;
    GridPos WorldToGrid(Vector2 pos) const;

    void HandleInput();
    void HandleMenuInput();
    void HandlePlayingInput();
    void ResetLevel();
    void ApplyHint();

    void StartPath(GridPos pos);
    void AddPathPoint(GridPos pos);
    void EndPath();
    void ValidateBoard();

    LevelManager levelManager;
    std::unique_ptr<Board> board;
    Path playerPath;
    Path solution;
    
    int screenWidth, screenHeight;
    float cellSize;
    Vector2 gridOffset;

    VFXSystem* vfx;
    GameState state;

    bool isDrawing;
    GridPos lastValidPos;
    GridPos hoveredPos;
    
    Difficulty currentDifficulty;
    int movesCounter;
};
