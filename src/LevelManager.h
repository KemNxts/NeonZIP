#pragma once
#include "PuzzleGenerator.h"
#include <string>
#include <map>

class LevelManager {
public:
    LevelManager();
    
    PuzzleData LoadLevel(Difficulty diff, int levelId);
    void UnlockNextLevel(Difficulty diff);
    int GetMaxUnlockedLevel(Difficulty diff) const;
    int GetCurrentLevelId() const { return currentLevelId; }
    void SetCurrentLevelId(int id) { currentLevelId = id; }
    
    int GetMaxLevels(Difficulty diff) const;

private:
    void LoadSaveData();
    void SaveData();

    std::map<Difficulty, int> maxUnlocked;
    int currentLevelId;
};
