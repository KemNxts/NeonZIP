#pragma once
#include <raylib.h>

class GameManager;
class Board;
class VFXSystem;

class Renderer {
public:
    Renderer();
    void DrawGame(const GameManager* gameManager, const VFXSystem* vfx);

private:
    void DrawGrid(const Board* board, float cellSize, Vector2 offset);
    void DrawPaths(const GameManager* gameManager, const Board* board, float cellSize, Vector2 offset);
    void DrawNodes(const GameManager* gameManager, const Board* board, float cellSize, Vector2 offset);
    void DrawVFX(const VFXSystem* vfx);
    
    void DrawMainMenu(const GameManager* gameManager);
    void DrawGameplayUI(const GameManager* gameManager);
    
    void DrawNeonCircle(Vector2 pos, float radius, Color color, float intensity, bool isError);
    void DrawNeonLine(Vector2 start, Vector2 end, float thickness, Color color, bool isError);
    void DrawButton(Rectangle rect, const char* text, Color color, bool isHovered, bool isSelected);

    float time;
};
