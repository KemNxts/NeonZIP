#include "LevelExporter.h"
#include "PuzzleGenerator.h"
#include "Board.h"
#include <iostream>
#include <fstream>
#include <filesystem>
#include <sys/stat.h>

void LevelExporter::ExportInitialLevels() {
    std::string baseDir = "assets/levels/";
    std::filesystem::create_directories(baseDir + "beginner");
    std::filesystem::create_directories(baseDir + "intermediate");
    std::filesystem::create_directories(baseDir + "expert");

    auto getSnakePath = [](int size) {
        std::vector<GridPos> path;
        for (int y = 0; y < size; y++) {
            if (y % 2 == 0) {
                for (int x = 0; x < size; x++) path.push_back({x, y});
            } else {
                for (int x = size - 1; x >= 0; x--) path.push_back({x, y});
            }
        }
        return path;
    };
    


    auto applyTransform = [](std::vector<GridPos>& path, int size, int transformId) {
        for (auto& p : path) {
            if (transformId % 2 == 1) p.x = size - 1 - p.x; // Flip X
            if (transformId % 4 >= 2) p.y = size - 1 - p.y; // Flip Y
            if (transformId % 8 >= 4) { int temp = p.x; p.x = p.y; p.y = temp; } // Transpose
        }
        if (transformId % 16 >= 8) std::reverse(path.begin(), path.end()); // Reverse
    };

    auto exportLevel = [&](Difficulty diff, int id, const std::string& path_str) {
        int size = (diff == Difficulty::BEGINNER) ? 5 : ((diff == Difficulty::INTERMEDIATE) ? 7 : 9);
        int k = (diff == Difficulty::BEGINNER) ? 5 : ((diff == Difficulty::INTERMEDIATE) ? 7 : 9);
        
        std::vector<GridPos> path = getSnakePath(size);
        applyTransform(path, size, id); // id is 1 to 10, gives 10 variations

        std::ofstream out(path_str);
        if (!out) return;

        out << "[Header]\n";
        out << "Size=" << size << "\n";
        out << "TotalNodes=" << k << "\n\n";

        out << "[Nodes]\n";
        int targetLen = size * size;
        int step = (targetLen - 1) / (k - 1);
        for (int i = 0; i < k; i++) {
            int index = (i == k - 1) ? (targetLen - 1) : (i * step);
            out << (i + 1) << " " << path[index].x << " " << path[index].y << "\n";
        }
        
        out << "\n[Solution]\n";
        for (auto p : path) {
            out << p.x << " " << p.y << "\n";
        }
    };

    for (int i = 1; i <= 10; i++) {
        exportLevel(Difficulty::BEGINNER, i, baseDir + "beginner/level_" + std::to_string(i) + ".level");
        exportLevel(Difficulty::INTERMEDIATE, i, baseDir + "intermediate/level_" + std::to_string(i) + ".level");
        exportLevel(Difficulty::EXPERT, i, baseDir + "expert/level_" + std::to_string(i) + ".level");
    }
}
