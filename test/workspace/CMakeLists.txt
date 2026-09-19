cmake_minimum_required(VERSION 3.25)

project(devcontainer-cpp-smoke LANGUAGES C CXX ASM)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(smoke src/main.cpp)
target_compile_options(smoke PRIVATE -Wall -Wextra -Wpedantic)
