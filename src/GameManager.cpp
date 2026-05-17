#include "GameManager.h"
#include "Solver.h"
#include "VFX.h"
#include <algorithm>
#include <raylib.h>

GameManager::GameManager(int screenWidth, int screenHeight) 
    : screenWidth(screenWidth), screenHeight(screenHeight), vfx(nullptr), state(GameState::MENU), isDrawing(false), currentDifficulty(Difficulty::BEGINNER), movesCounter(0) 
{
}

void GameManager::GenerateLevel(Difficulty diff) {
    LoadSpecificLevel(diff, levelManager.GetMaxUnlockedLevel(diff));
}

void GameManager::LoadSpecificLevel(Difficulty diff, int id) {
    currentDifficulty = diff;
    PuzzleData data = levelManager.LoadLevel(diff, id);
    board = std::move(data.board);
    solution = data.solution;
    playerPath.points.clear();
    isDrawing = false;
    state = GameState::PLAYING;
    movesCounter = 0;

    int size = board->GetSize();
    float minDimension = (float)(screenWidth < screenHeight ? screenWidth : screenHeight);
    cellSize = (minDimension * 0.8f) / size;
    gridOffset.x = (screenWidth - (size * cellSize)) / 2.0f;
    gridOffset.y = (screenHeight - (size * cellSize)) / 2.0f;
}

Vector2 GameManager::GridToWorld(GridPos pos) const {
    return {
        gridOffset.x + pos.x * cellSize + cellSize / 2.0f,
        gridOffset.y + pos.y * cellSize + cellSize / 2.0f
    };
}

GridPos GameManager::WorldToGrid(Vector2 pos) const {
    int x = (int)((pos.x - gridOffset.x) / cellSize);
    int y = (int)((pos.y - gridOffset.y) / cellSize);
    return {x, y};
}

void GameManager::Update(float dt) {
    if (vfx) vfx->SetMousePos(GetMousePosition());
    
    hoveredPos = WorldToGrid(GetMousePosition());

    if (state == GameState::MENU) {
        HandleMenuInput();
    } else if (state == GameState::LEVEL_COMPLETE) {
        if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON)) {
            int nextId = levelManager.GetCurrentLevelId() + 1;
            if (nextId > levelManager.GetMaxLevels(currentDifficulty)) {
                state = GameState::MENU;
            } else {
                LoadSpecificLevel(currentDifficulty, nextId);
            }
        }
    } else {
        HandlePlayingInput();
    }
}

void GameManager::HandleMenuInput() {
    if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON)) {
        Vector2 mouse = GetMousePosition();
        if (mouse.x > screenWidth/2.0f - 100 && mouse.x < screenWidth/2.0f + 100) {
            if (mouse.y > 300 && mouse.y < 350) currentDifficulty = Difficulty::BEGINNER;
            else if (mouse.y > 380 && mouse.y < 430) currentDifficulty = Difficulty::INTERMEDIATE;
            else if (mouse.y > 460 && mouse.y < 510) currentDifficulty = Difficulty::EXPERT;
            else if (mouse.y > 560 && mouse.y < 610) GenerateLevel(currentDifficulty);
        }
    }
}

void GameManager::HandlePlayingInput() {
    Vector2 mousePos = GetMousePosition();
    GridPos gPos = WorldToGrid(mousePos);

    if (IsMouseButtonPressed(MOUSE_RIGHT_BUTTON)) {
        if (!playerPath.points.empty()) {
            playerPath.points.pop_back();
            if (!playerPath.points.empty()) {
                lastValidPos = playerPath.points.back();
            }
        }
        return;
    }

    if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON)) {
        if (mousePos.y >= 10 && mousePos.y <= 40) {
            if (mousePos.x >= 10 && mousePos.x <= 90) { ResetLevel(); return; }
            if (mousePos.x >= 100 && mousePos.x <= 180) { ApplyHint(); return; }
            if (mousePos.x >= 190 && mousePos.x <= 270) { state = GameState::MENU; return; }
        }

        if (board->IsValidPos(gPos)) {
            if (playerPath.points.empty()) {
                if (board->GetTile(gPos).type == TileType::NODE && board->GetTile(gPos).sequenceNum == 1) {
                    StartPath(gPos);
                }
            } else {
                if (gPos == playerPath.points.back()) {
                    isDrawing = true;
                    lastValidPos = gPos;
                } else if (playerPath.Contains(gPos)) {
                    playerPath.BacktrackTo(gPos);
                    isDrawing = true;
                    lastValidPos = gPos;
                }
            }
        }
    } else if (IsMouseButtonDown(MOUSE_LEFT_BUTTON) && isDrawing) {
        if (board->IsValidPos(gPos) && gPos != lastValidPos) {
            if (board->IsAdjacent(lastValidPos, gPos)) {
                AddPathPoint(gPos);
            }
        }
    } else if (IsMouseButtonReleased(MOUSE_LEFT_BUTTON) && isDrawing) {
        EndPath();
    }
}

void GameManager::StartPath(GridPos pos) {
    movesCounter++;
    isDrawing = true;
    playerPath = Path(Color{200, 255, 255, 255});
    playerPath.AddPoint(pos);
    lastValidPos = pos;
    if (vfx) vfx->EmitBurst(GridToWorld(pos), playerPath.color, 20);
}

void GameManager::AddPathPoint(GridPos pos) {
    if (playerPath.points.size() > 1 && playerPath.points[playerPath.points.size() - 2] == pos) {
        playerPath.points.pop_back();
        lastValidPos = pos;
        return;
    }

    if (playerPath.Contains(pos)) return; 

    int expectedNext = 2;
    for (auto p : playerPath.points) {
        if (board->GetTile(p).type == TileType::NODE) {
            expectedNext = board->GetTile(p).sequenceNum + 1;
        }
    }

    const Tile& t = board->GetTile(pos);
    if (t.type == TileType::NODE) {
        if (t.sequenceNum != expectedNext) {
            return; 
        }
    }

    playerPath.AddPoint(pos);
    lastValidPos = pos;
    if (vfx) vfx->EmitBurst(GridToWorld(pos), playerPath.color, 5);

    if (t.type == TileType::NODE && t.sequenceNum == board->GetTotalNodes()) {
        EndPath();
    }
}

void GameManager::EndPath() {
    isDrawing = false;
    if (playerPath.points.size() == (size_t)(board->GetSize() * board->GetSize())) {
        GridPos lastPos = playerPath.points.back();
        if (board->GetTile(lastPos).type == TileType::NODE && 
            board->GetTile(lastPos).sequenceNum == board->GetTotalNodes()) {
            state = GameState::LEVEL_COMPLETE;
            levelManager.UnlockNextLevel(currentDifficulty);
            if (vfx) vfx->EmitBurst(GridToWorld(lastPos), playerPath.color, 40);
        }
    }
}

void GameManager::ValidateBoard() {
}

void GameManager::ResetLevel() {
    playerPath.points.clear();
    isDrawing = false;
    movesCounter = 0;
}

void GameManager::ApplyHint() {
    if (playerPath.points.size() < solution.points.size()) {
        size_t nextIndex = playerPath.points.size();
        GridPos nextPos = solution.points[nextIndex];
        
        if (nextIndex == 0) {
            StartPath(nextPos);
            isDrawing = false;
        } else {
            bool matches = true;
            for (size_t i = 0; i < playerPath.points.size(); i++) {
                if (playerPath.points[i] != solution.points[i]) {
                    matches = false;
                    break;
                }
            }
            if (!matches) {
                ResetLevel();
                StartPath(solution.points[0]);
                isDrawing = false;
                return;
            }
            
            AddPathPoint(nextPos);
            isDrawing = false; 
        }
    }
}
