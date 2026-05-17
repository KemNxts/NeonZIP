#include "Renderer.h"
#include "GameManager.h"
#include "Board.h"
#include "VFX.h"
#include <cmath>

Renderer::Renderer() : time(0.0f) {}

void Renderer::DrawGame(const GameManager* gameManager, const VFXSystem* vfx) {
    time += GetFrameTime();
    
    ClearBackground(Color{5, 8, 12, 255}); // Dark navy/black background
    
    if (gameManager->GetState() == GameState::MENU) {
        DrawMainMenu(gameManager);
        return;
    }
    
    const Board* board = gameManager->GetBoard();
    float cellSize = gameManager->GetCellSize();
    Vector2 offset = gameManager->GetGridOffset();
    
    DrawGrid(board, cellSize, offset);
    
    BeginBlendMode(BLEND_ADDITIVE);
    
    DrawPaths(gameManager, board, cellSize, offset);
    DrawNodes(gameManager, board, cellSize, offset);
    DrawVFX(vfx);
    
    EndBlendMode();
    
    DrawGameplayUI(gameManager);
}

void Renderer::DrawGrid(const Board* board, float cellSize, Vector2 offset) {
    int size = board->GetSize();
    
    for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
            Rectangle rect = {
                offset.x + x * cellSize,
                offset.y + y * cellSize,
                cellSize,
                cellSize
            };
            
            Color cellColor = ((x + y) % 2 == 0) ? Color{20, 25, 35, 255} : Color{15, 20, 30, 255};
            DrawRectangleRec(rect, cellColor);
            DrawRectangleLinesEx(rect, 1, Color{30, 35, 45, 255});
        }
    }
    
    DrawRectangleLinesEx(
        {offset.x, offset.y, size * cellSize, size * cellSize},
        2, Color{50, 55, 65, 255}
    );
}

void Renderer::DrawNeonLine(Vector2 start, Vector2 end, float thickness, Color color, bool isError) {
    Color baseCol = isError ? RED : color;
    DrawLineEx(start, end, thickness * 0.5f, Fade(baseCol, 0.4f));
    DrawLineEx(start, end, thickness * 0.2f, baseCol);
}

void Renderer::DrawNeonCircle(Vector2 pos, float radius, Color color, float intensity, bool isError) {
    Color baseCol = isError ? RED : color;
    DrawCircleV(pos, radius, Color{20, 25, 35, 255});
    DrawCircleLinesV(pos, radius, Fade(baseCol, intensity));
    DrawCircleLinesV(pos, radius - 1.0f, Fade(baseCol, intensity * 0.5f));
}

void Renderer::DrawPaths(const GameManager* gameManager, const Board* board, float cellSize, Vector2 offset) {
    auto drawLinePath = [&](const std::vector<GridPos>& pts, Color col, bool isError) {
        if (pts.size() < 2) return;
        for (size_t i = 0; i < pts.size() - 1; i++) {
            Vector2 p1 = {offset.x + pts[i].x * cellSize + cellSize/2, offset.y + pts[i].y * cellSize + cellSize/2};
            Vector2 p2 = {offset.x + pts[i+1].x * cellSize + cellSize/2, offset.y + pts[i+1].y * cellSize + cellSize/2};
            DrawNeonLine(p1, p2, cellSize * 0.15f, col, isError);
            DrawNeonCircle(p1, cellSize * 0.08f, col, 1.0f, isError);
        }
        Vector2 lastP = {offset.x + pts.back().x * cellSize + cellSize/2, offset.y + pts.back().y * cellSize + cellSize/2};
        DrawNeonCircle(lastP, cellSize * 0.08f, col, 1.0f, isError);
    };
    
    const Path* active = gameManager->GetPlayerPath();
    if (active && !active->points.empty()) {
        drawLinePath(active->points, active->color, active->isError);
    }
}

void Renderer::DrawNodes(const GameManager* gameManager, const Board* board, float cellSize, Vector2 offset) {
    int size = board->GetSize();
    GridPos hovered = gameManager->GetHoveredPos();
    
    for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
            const Tile& t = board->GetTile(x, y);
            if (t.type == TileType::NODE) {
                Vector2 pos = {
                    offset.x + x * cellSize + cellSize/2,
                    offset.y + y * cellSize + cellSize/2
                };
                
                bool isHovered = (hovered.x == x && hovered.y == y);
                float radius = cellSize * 0.35f;
                
                Color outlineColor = isHovered ? Color{200, 255, 255, 255} : Color{150, 160, 170, 255};
                
                DrawNeonCircle(pos, radius, outlineColor, 1.0f, t.isError);
                
                const char* numText = TextFormat("%d", t.sequenceNum);
                int fontSize = (int)(cellSize * 0.4f);
                int tw = MeasureText(numText, fontSize);
                DrawText(numText, pos.x - tw/2, pos.y - fontSize/2, fontSize, WHITE);
            }
        }
    }
}

void Renderer::DrawVFX(const VFXSystem* vfx) {
    for (const auto& p : vfx->GetParticles()) {
        float alpha = p.life / p.maxLife;
        DrawCircleV(p.position, p.size, Fade(p.color, alpha));
        DrawCircleV(p.position, p.size * 0.5f, Fade(WHITE, alpha));
    }
    DrawCircleV(vfx->GetMousePos(), 3, Color{255, 255, 255, 100});
}

void Renderer::DrawButton(Rectangle rect, const char* text, Color color, bool isHovered, bool isSelected) {
    Color drawColor = isHovered ? WHITE : color;
    if (isSelected) drawColor = WHITE;
    
    DrawRectangleLinesEx(rect, 1, drawColor);
    if (isHovered || isSelected) {
        DrawRectangleRec(rect, Fade(drawColor, 0.1f));
    }
    
    int tw = MeasureText(text, 20);
    DrawText(text, rect.x + rect.width/2 - tw/2, rect.y + rect.height/2 - 10, 20, drawColor);
}

void Renderer::DrawMainMenu(const GameManager* gameManager) {
    int screenWidth = GetScreenWidth();
    int screenHeight = GetScreenHeight();
    
    DrawText("CYBER LOGIC", screenWidth/2 - MeasureText("CYBER LOGIC", 40)/2, 100, 40, WHITE);
    
    Vector2 mouse = GetMousePosition();
    Difficulty currentDiff = gameManager->GetDifficulty();
    
    const LevelManager& lm = gameManager->GetLevelManager();
    int bLvl = lm.GetMaxUnlockedLevel(Difficulty::BEGINNER);
    int iLvl = lm.GetMaxUnlockedLevel(Difficulty::INTERMEDIATE);
    int eLvl = lm.GetMaxUnlockedLevel(Difficulty::EXPERT);
    
    Rectangle btnBeginner = { screenWidth/2.0f - 120, 300, 240, 50 };
    Rectangle btnIntermed = { screenWidth/2.0f - 120, 380, 240, 50 };
    Rectangle btnExpert = { screenWidth/2.0f - 120, 460, 240, 50 };
    Rectangle btnPlay = { screenWidth/2.0f - 120, 560, 240, 50 };
    
    DrawButton(btnBeginner, TextFormat("BEGINNER (LVL %d)", bLvl), Color{150, 160, 170, 255}, CheckCollisionPointRec(mouse, btnBeginner), currentDiff == Difficulty::BEGINNER);
    DrawButton(btnIntermed, TextFormat("INTERMEDIATE (LVL %d)", iLvl), Color{150, 160, 170, 255}, CheckCollisionPointRec(mouse, btnIntermed), currentDiff == Difficulty::INTERMEDIATE);
    DrawButton(btnExpert, TextFormat("EXPERT (LVL %d)", eLvl), Color{150, 160, 170, 255}, CheckCollisionPointRec(mouse, btnExpert), currentDiff == Difficulty::EXPERT);
    DrawButton(btnPlay, "CONTINUE", Color{200, 255, 255, 255}, CheckCollisionPointRec(mouse, btnPlay), false);
}

void Renderer::DrawGameplayUI(const GameManager* gameManager) {
    Vector2 mouse = GetMousePosition();
    
    Rectangle btnReset = { 10, 10, 80, 30 };
    Rectangle btnHint = { 100, 10, 80, 30 };
    Rectangle btnMenu = { 190, 10, 80, 30 };
    
    DrawButton(btnReset, "RESET", Color{150, 160, 170, 255}, CheckCollisionPointRec(mouse, btnReset), false);
    DrawButton(btnHint, "HINT", Color{150, 160, 170, 255}, CheckCollisionPointRec(mouse, btnHint), false);
    DrawButton(btnMenu, "MENU", Color{150, 160, 170, 255}, CheckCollisionPointRec(mouse, btnMenu), false);
    
    const char* movesText = TextFormat("MOVES: %d", gameManager->GetMoves());
    DrawText(movesText, 300, 15, 20, Color{200, 200, 200, 255});
    
    Difficulty diff = gameManager->GetDifficulty();
    const char* diffText = diff == Difficulty::BEGINNER ? "BEGINNER" : 
                           (diff == Difficulty::INTERMEDIATE ? "INTERMEDIATE" : "EXPERT");
                           
    int levelId = gameManager->GetLevelManager().GetCurrentLevelId();
    const char* levelText = TextFormat("%s - LEVEL %d", diffText, levelId);
    int tw = MeasureText(levelText, 20);
    DrawText(levelText, GetScreenWidth() - tw - 20, 15, 20, Color{150, 160, 170, 255});
    
    if (gameManager->GetState() == GameState::LEVEL_COMPLETE) {
        const char* winText = "LEVEL COMPLETE";
        int maxLvl = gameManager->GetLevelManager().GetMaxLevels(diff);
        const char* nextText = (levelId >= maxLvl) ? "Click to return to MENU" : "Click for NEXT LEVEL";
        int width = MeasureText(winText, 40);
        int nextWidth = MeasureText(nextText, 20);
        
        DrawRectangle(0, GetScreenHeight()/2 - 60, GetScreenWidth(), 140, Fade(Color{5, 8, 12, 255}, 0.9f));
        DrawRectangleLines(0, GetScreenHeight()/2 - 60, GetScreenWidth(), 140, Color{50, 55, 65, 255});
        DrawText(winText, GetScreenWidth()/2 - width/2, GetScreenHeight()/2 - 30, 40, WHITE);
        DrawText(nextText, GetScreenWidth()/2 - nextWidth/2, GetScreenHeight()/2 + 30, 20, Color{150, 160, 170, 255});
    }
}
