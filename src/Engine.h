#pragma once
#include <memory>
#include "GameManager.h"
#include "Renderer.h"
#include "VFX.h"

class Engine {
public:
    Engine();
    ~Engine();

    void Init();
    void Run();

private:
    void Update();
    void Draw();

    std::unique_ptr<GameManager> gameManager;
    std::unique_ptr<Renderer> renderer;
    std::unique_ptr<VFXSystem> vfx;

    int screenWidth;
    int screenHeight;
};
