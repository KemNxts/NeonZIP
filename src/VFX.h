#pragma once
#include <raylib.h>
#include <vector>

struct Particle {
    Vector2 position;
    Vector2 velocity;
    Color color;
    float life;
    float maxLife;
    float size;
};

class VFXSystem {
public:
    void Update(float dt);
    void Draw() const;

    void EmitBurst(Vector2 position, Color color, int count);
    void SetMousePos(Vector2 pos) { mousePos = pos; }

    const std::vector<Particle>& GetParticles() const { return particles; }
    Vector2 GetMousePos() const { return mousePos; }

private:
    std::vector<Particle> particles;
    Vector2 mousePos;
};
