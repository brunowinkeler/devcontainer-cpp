# Using the dev container

A practical walkthrough: starting a project, what arrives for free, and how to wire the
templates in [`cmake/`](../cmake) for host, Windows and bare-metal ARM builds.

For the full list of what is installed and at which version, see [TOOLS.md](TOOLS.md).

---

## 1. Starting a project

Two files are enough.

`.devcontainer/Dockerfile`:

```dockerfile
FROM ghcr.io/brunowinkeler/devcontainer-cpp:1.0.0
HEALTHCHECK NONE
```

`.devcontainer/devcontainer.json`:

```json
{
  "name": "my-project",
  "build": { "dockerfile": "Dockerfile" }
}
```

Then **Dev Containers: Reopen in Container** in VS Code.

A `Dockerfile` is used instead of `"image"` so Dependabot can bump the `FROM` line, and so
you have somewhere to add project-specific packages later:

```dockerfile
FROM ghcr.io/brunowinkeler/devcontainer-cpp:1.0.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends libsqlite3-dev \
 && rm -rf /var/lib/apt/lists/*

HEALTHCHECK NONE
```

Pin an exact version (`1.0.0`) for reproducibility, or track `1` to pick up new tools
without breaking changes. See the versioning table in the [README](../README.md).

### Things a project usually adds

```json
{
  "name": "my-project",
  "build": { "dockerfile": "Dockerfile" },
  "postCreateCommand": "git submodule update --init --recursive",
  "runArgs": ["--device=/dev/bus/usb"]
}
```

`runArgs` is only needed for hardware debug probes, and only works on a Linux host.

---

## 2. What arrives for free

Nothing else has to be declared. The image carries a `devcontainer.metadata` label that
VS Code merges into your project's configuration:

- **25 extensions** — clangd, CMake Tools, cpptools (debugger), Cortex-Debug and the
  `mcu-debug` set, serial monitor, hex editor, test explorer, and the GitHub tooling.
- **Editor settings** — clangd drives IntelliSense (`C_Cpp.intelliSenseEngine` is
  `disabled`), clangd is the C/C++ formatter, CMake Tools is forced to presets mode, and
  Cortex-Debug already points at `gdb-multiarch`, `arm-none-eabi-objdump` and `openocd`.
- **Ports** — 6080 (noVNC) and 5901 (VNC).
- **Environment** — `CMAKE_GENERATOR=Ninja`, `CMAKE_EXPORT_COMPILE_COMMANDS=On`,
  `CMAKE_POLICY_VERSION_MINIMUM=3.5`, ccache and CPM caches under `/cache`.

To override any of it, declare the same key in your own `devcontainer.json`; the project's
value wins.

### clangd and the compilation database

`~/.cppdev/compile_commands.json` is seeded with `[]` inside the image so clangd works
before you ever configure CMake. After the first configure, CMake Tools copies the real
database there via `cmake.copyCompileCommands`. If clangd reports unknown flags for a cross
compiler, that is what the pre-set `--query-driver` argument handles — it already covers
`gcc-15`, `clang`, `arm-none-eabi-*` and `x86_64-w64-mingw32-*`.

---

## 3. The cmake templates

[`cmake/`](../cmake) is a copy-paste kit, not a library. Take the pieces you need into your
own project; nothing references the container by path.

| File | Copy it to | Use it for |
| --- | --- | --- |
| [`toolchain-windows-mingw.cmake`](../cmake/toolchain-windows-mingw.cmake) | `cmake/` | Linux → Windows x86_64 cross builds |
| [`toolchain-arm-none-eabi.cmake`](../cmake/toolchain-arm-none-eabi.cmake) | `cmake/` | Cortex-M/R bare metal |
| [`CMakePresets-template.json`](../cmake/CMakePresets-template.json) | `CMakePresets.json` | The presets that drive both |

The preset template ships eight configure presets. Delete the ones you do not need:

| Preset | Toolchain | Output |
| --- | --- | --- |
| `linux-debug` / `linux-release` | GCC 15 | host ELF |
| `linux-clang-debug` | Clang 22 | host ELF |
| `linux-asan` | Clang 22 | host ELF with ASan + UBSan |
| `windows-mingw-debug` / `windows-mingw-release` | mingw-w64 GCC 13 | static `.exe` |
| `arm-none-eabi-debug` / `arm-none-eabi-release` | Arm GNU Toolchain 15.2 | ARM ELF |

All of them use Ninja and build into `build/<preset-name>/`, which keeps host, Windows and
firmware artifacts from colliding.

### Windows cross compilation

```bash
cmake --preset windows-mingw-release
cmake --build --preset windows-mingw-release
file build/windows-mingw-release/my-app.exe
# -> PE32+ executable for MS Windows, x86-64
```

What the toolchain file does and why:

- `CMAKE_SYSTEM_NAME Windows` plus the `x86_64-w64-mingw32-*` compilers.
- `CMAKE_FIND_ROOT_PATH` with `FIND_ROOT_PATH_MODE_LIBRARY/INCLUDE/PACKAGE ONLY`. Without
  this a `find_package()` call can silently resolve a **host Linux** library into the
  Windows build. It only bites once you depend on something found on the system, but it is
  worth having from the start.
- `STATIC_BUILD` (default `ON`) adds `-static`, so the result imports only
  `KERNEL32.dll` and `msvcrt.dll`. Nothing to ship next to the executable.

Two things to know:

- The cross compiler is **GCC 13**, the newest Ubuntu 26.04 offers. The Windows target is
  therefore capped at C++20 in practice — `<print>` and other C++23 library features are
  unavailable there even though the host compilers are GCC 15 and Clang 22. Setting
  `CMAKE_CXX_STANDARD 20` project-wide keeps both targets building from identical sources.
- The container has no `wine`, so a cross-built `.exe` cannot be executed here. Guard your
  tests:

  ```cmake
  if(BUILD_TESTING AND NOT CMAKE_CROSSCOMPILING)
      add_test(NAME my_test COMMAND my_test_binary)
  endif()
  ```

  If you do want to smoke-test locally, add `RUN apt-get install -y wine64` to your project
  Dockerfile (~1 GB).

### Bare-metal ARM

`toolchain-arm-none-eabi.cmake` is a starting point, not a finished port. Adjust
`ARM_CPU_FLAGS` to your MCU and add your linker script:

```cmake
set(ARM_CPU_FLAGS "-mcpu=cortex-m33 -mthumb -mfpu=fpv5-sp-d16 -mfloat-abi=hard")
```

```cmake
target_link_options(firmware PRIVATE -T${CMAKE_SOURCE_DIR}/linker/stm32.ld)
```

It sets `CMAKE_SYSTEM_NAME Generic` and `CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY`,
without which CMake's compiler check fails: a bare-metal toolchain cannot link a runnable
executable. The default flags include `-ffunction-sections -fdata-sections` with
`--gc-sections`, and `nano.specs`/`nosys.specs` for a small newlib with stubbed syscalls.

Flashing and debugging:

```bash
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg
probe-rs run --chip STM32F407VGTx build/arm-none-eabi-release/firmware.elf
qemu-system-arm -M mps2-an385 -nographic -kernel build/arm-none-eabi-release/firmware.elf
```

Cortex-Debug is already configured, so a `launch.json` only needs the target specifics:

```json
{
  "name": "Debug firmware",
  "type": "cortex-debug",
  "request": "launch",
  "servertype": "openocd",
  "executable": "${workspaceFolder}/build/arm-none-eabi-debug/firmware.elf",
  "configFiles": ["interface/stlink.cfg", "target/stm32f4x.cfg"],
  "svdFile": "${workspaceFolder}/svd/STM32F407.svd"
}
```

USB probes are **not** reachable from a Windows host — Docker Desktop has no USB
passthrough. Use [usbipd-win](https://github.com/dorssel/usbipd-win), or run the container
on Linux and add `"runArgs": ["--device=/dev/bus/usb"]`. `qemu-system-arm` needs no
hardware at all.

---

## 4. Day-to-day

From VS Code: pick a preset in the CMake Tools status bar, then build, test and debug from
there. From a terminal it is the same three commands everywhere:

```bash
cmake --preset <name>
cmake --build --preset <name>
ctest --preset <name>
```

Other things the image is already set up for:

```bash
ccache --show-stats                       # shared cache across rebuilds
gcovr --root . build/coverage             # coverage from a -coverage build
clang-tidy src/foo.cpp -p build/linux-debug
cppcheck --project=build/linux-debug/compile_commands.json
valgrind --leak-check=full ./build/linux-debug/my-app
bear -- make                              # compile_commands.json for Makefile projects
```

Dependencies, if you need them: CPM is already on the CMake module path
(`include(CPM)` works with no vendoring), and Conan has a default profile that emits Ninja.

### Graphical applications

Run the app with `DISPLAY=:1` (already exported) and open `http://localhost:6080`. The
password is `vscode`. Rendering goes through Mesa `llvmpipe`, so OpenGL 4.5 works with no
GPU. For headless runs, `xvfb-run -a ./my-app`.

---

## 5. Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `Compatibility with CMake < 3.5 has been removed` | A dependency declares an ancient `cmake_minimum_required`. The image exports `CMAKE_POLICY_VERSION_MINIMUM=3.5` to absorb this; if you unset it, pass `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` for that project. |
| SDL configures without Wayland or PulseAudio | Almost always a missing `pkg-config` in a derived image. It is present here — check you did not strip it. |
| clangd shows errors that the build does not | The compilation database is stale. Reconfigure, or check that `cmake.copyCompileCommands` still points at `~/.cppdev/compile_commands.json`. |
| `ctest` reports no tests for a mingw preset | Expected. Windows binaries cannot run here; guard `add_test` with `NOT CMAKE_CROSSCOMPILING`. |
| `<print>` not found in the Windows build | The mingw cross compiler is GCC 13. Use C++20 for that target. |
| The debug probe is not listed | USB passthrough on a Windows host requires usbipd-win. |
| Extensions did not install | The metadata label only travels through the image. If you rebuilt the base yourself with plain `docker build`, the features and metadata were dropped — build with `devcontainer build`. |

---

## 6. Worked examples

Two complete projects, both built exactly the way described above and both free of external
dependencies.

**[devcontainer-cpp-example](https://github.com/brunowinkeler/devcontainer-cpp-example)** — a
terminal application that builds for Linux with GCC and Clang, cross compiles to a static
Windows `.exe`, runs CTest on the host only, and debugs with `gdb`:

```
devcontainer-cpp-example/
├── .devcontainer/          Dockerfile (2 lines) + devcontainer.json
├── .vscode/launch.json     cppdbg configuration
├── cmake/                  toolchain-windows-mingw.cmake, copied from this repo
├── src/                    build_info.{hpp,cpp}, sieve.{hpp,cpp}, main.cpp
├── tests/test_sieve.cpp    plain assertions, no test framework
├── CMakeLists.txt
└── CMakePresets.json
```

**[devcontainer-cpp-embedded-example](https://github.com/brunowinkeler/devcontainer-cpp-embedded-example)**
— bare-metal firmware for the STM32F4DISCOVERY, with no HAL, CMSIS or SDK. It links against a
custom linker script, emits `.bin`/`.hex`, flashes through OpenOCD and debugs with
Cortex-Debug. `test/verify.sh` asserts the reset vector and stack top so the image is
validated without the board:

```
devcontainer-cpp-embedded-example/
├── .devcontainer/          Dockerfile (2 lines) + devcontainer.json
├── .vscode/launch.json     cortex-debug over OpenOCD and QEMU
├── cmake/                  toolchain-arm-none-eabi.cmake, copied from this repo
├── linker/stm32f407vg.ld   memory map and sections
├── src/                    startup.cpp, registers.hpp, board.{hpp,cpp}, main.cpp
├── test/verify.sh          checks the image without hardware
├── CMakeLists.txt
└── CMakePresets.json
```
