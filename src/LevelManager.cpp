#include "LevelManager.h"
#include "Board.h"
#include <fstream>
#include <sstream>
#include <iostream>

LevelManager::LevelManager() : currentLevelId(1) {
    maxUnlocked[Difficulty::BEGINNER] = 1;
    maxUnlocked[Difficulty::INTERMEDIATE] = 1;
    maxUnlocked[Difficulty::EXPERT] = 1;
    LoadSaveData();
}

void LevelManager::LoadSaveData() {
    std::ifstream in("save.dat");
    if (!in) return;
    int b, i, e;
    if (in >> b >> i >> e) {
        maxUnlocked[Difficulty::BEGINNER] = b;
        maxUnlocked[Difficulty::INTERMEDIATE] = i;
        maxUnlocked[Difficulty::EXPERT] = e;
    }
}

void LevelManager::SaveData() {
    std::ofstream out("save.dat");
    if (out) {
        out << maxUnlocked[Difficulty::BEGINNER] << " " 
            << maxUnlocked[Difficulty::INTERMEDIATE] << " " 
            << maxUnlocked[Difficulty::EXPERT] << "\n";
    }
}

void LevelManager::UnlockNextLevel(Difficulty diff) {
    if (currentLevelId == maxUnlocked[diff]) {
        if (maxUnlocked[diff] < GetMaxLevels(diff)) {
            maxUnlocked[diff]++;
            SaveData();
        }
    }
}

int LevelManager::GetMaxLevels(Difficulty diff) const {
    std::string folder = "beginner";
    if (diff == Difficulty::INTERMEDIATE) folder = "intermediate";
    if (diff == Difficulty::EXPERT) folder = "expert";

    int count = 0;
    while (true) {
        std::ifstream in("assets/levels/" + folder + "/level_" + std::to_string(count + 1) + ".level");
        if (!in) break;
        count++;
    }
    return count > 0 ? count : 1;
}

int LevelManager::GetMaxUnlockedLevel(Difficulty diff) const {
    auto it = maxUnlocked.find(diff);
    return it != maxUnlocked.end() ? it->second : 1;
}

PuzzleData LevelManager::LoadLevel(Difficulty diff, int levelId) {
    std::string folder = "beginner";
    if (diff == Difficulty::INTERMEDIATE) folder = "intermediate";
    if (diff == Difficulty::EXPERT) folder = "expert";

    std::string path = "assets/levels/" + folder + "/level_" + std::to_string(levelId) + ".level";
    std::ifstream in(path);
    
    PuzzleData data;
    
    if (!in) {
        // Fallback to generator if file missing
        return PuzzleGenerator::Generate(diff);
    }

    std::string line;
    int size = 5;
    int totalNodes = 5;

    enum Section { NONE, HEADER, NODES, SOLUTION };
    Section currentSection = NONE;

    while (std::getline(in, line)) {
        if (line.empty()) continue;
        if (line == "[Header]") { currentSection = HEADER; continue; }
        if (line == "[Nodes]") { currentSection = NODES; continue; }
        if (line == "[Solution]") { currentSection = SOLUTION; continue; }

        if (currentSection == HEADER) {
            if (line.find("Size=") == 0) size = std::stoi(line.substr(5));
            if (line.find("TotalNodes=") == 0) totalNodes = std::stoi(line.substr(11));
            if (data.board == nullptr) data.board = std::make_unique<Board>(size);
        } else if (currentSection == NODES) {
            std::stringstream ss(line);
            int seq, x, y;
            if (ss >> seq >> x >> y) {
                Color baseColor = Color{40, 45, 55, 255};
                data.board->SetNode({x, y}, seq, baseColor);
            }
        } else if (currentSection == SOLUTION) {
            std::stringstream ss(line);
            int x, y;
            if (ss >> x >> y) {
                data.solution.AddPoint({x, y});
            }
        }
    }

    if (data.board) {
        data.board->SetTotalNodes(totalNodes);
    }
    
    data.solution.color = Color{200, 255, 255, 255};
    currentLevelId = levelId;
    return data;
}
