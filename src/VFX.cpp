#include "VFX.h"
#include <cmath>

void VFXSystem::Update(float dt) {
    for (int i = (int)particles.size() - 1; i >= 0; i--) {
        particles[i].position.x += particles[i].velocity.x * dt;
        particles[i].position.y += particles[i].velocity.y * dt;
        particles[i].life -= dt;
        if (particles[i].life <= 0) {
            particles.erase(particles.begin() + i);
        }
    }
}

void VFXSystem::EmitBurst(Vector2 position, Color color, int count) {
    int adjustedCount = count / 3; 
    if (adjustedCount < 3) adjustedCount = 3;
    
    for (int i = 0; i < adjustedCount; i++) {
        float angle = (float)GetRandomValue(0, 360) * DEG2RAD;
        float speed = (float)GetRandomValue(20, 80);
        
        Particle p;
        p.position = position;
        p.velocity = {cosf(angle) * speed, sinf(angle) * speed};
        p.color = Color{200, 255, 255, 255}; // subtle white/cyan
        p.maxLife = (float)GetRandomValue(10, 30) / 100.0f;
        p.life = p.maxLife;
        p.size = (float)GetRandomValue(1, 3);
        
        particles.push_back(p);
    }
}
