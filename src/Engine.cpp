#include "Engine.h"
#include <raylib.h>

Engine::Engine() : screenWidth(1280), screenHeight(720) {}

Engine::~Engine() {
    CloseWindow();
}

void Engine::Init() {
    SetConfigFlags(FLAG_MSAA_4X_HINT);
    InitWindow(screenWidth, screenHeight, "Neon Zip Prototype");
    SetTargetFPS(60);

    vfx = std::make_unique<VFXSystem>();
    renderer = std::make_unique<Renderer>();
    gameManager = std::make_unique<GameManager>(screenWidth, screenHeight);
    
    gameManager->SetVFXSystem(vfx.get());
}

void Engine::Run() {
    while (!WindowShouldClose()) {
        Update();
        Draw();
    }
}

void Engine::Update() {
    float dt = GetFrameTime();
    gameManager->Update(dt);
    vfx->Update(dt);
}

void Engine::Draw() {
    BeginDrawing();
    ClearBackground(Color{10, 10, 18, 255}); 

    renderer->DrawGame(gameManager.get(), vfx.get());

    EndDrawing();
}
