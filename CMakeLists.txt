cmake_minimum_required(VERSION 3.14)
project(NeonZip CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

FetchContent_Declare(
    raylib
    URL https://github.com/raysan5/raylib/archive/refs/tags/5.0.tar.gz
)
FetchContent_MakeAvailable(raylib)

add_executable(NeonZip
    src/main.cpp
    src/Engine.cpp
    src/Board.cpp
    src/PuzzleGenerator.cpp
    src/Solver.cpp
    src/GameManager.cpp
    src/Renderer.cpp
    src/VFX.cpp
    src/LevelExporter.cpp
    src/LevelManager.cpp
)

target_link_libraries(NeonZip PRIVATE raylib)
