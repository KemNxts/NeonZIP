#pragma once
#include "Board.h"
#include <vector>
#include <algorithm>

class Path {
public:
    Path() : color(BLANK), completed(false), isError(false) {}
    Path(Color color) : color(color), completed(false), isError(false) {}

    int pairId;
    Color color;
    bool completed;
    bool isError;
    std::vector<GridPos> points;

    void AddPoint(GridPos pos) {
        points.push_back(pos);
    }

    void BacktrackTo(GridPos pos) {
        auto it = std::find(points.begin(), points.end(), pos);
        if (it != points.end()) {
            points.erase(it + 1, points.end());
        }
    }

    bool Contains(GridPos pos) const {
        return std::find(points.begin(), points.end(), pos) != points.end();
    }
};
