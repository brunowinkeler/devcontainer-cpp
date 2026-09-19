# Tool inventory

Everything installed in `ghcr.io/brunowinkeler/devcontainer-cpp`, with the exact version
that ships in the image. Versions come from the pinned `apt-requirements-*.json`,
`requirements.txt` and the `ARG` values in [.devcontainer/Dockerfile](../.devcontainer/Dockerfile),
and are verified on every build by [test/smoke.sh](../test/smoke.sh).

| | |
| --- | --- |
| Base image | `ubuntu:26.04` @ `sha256:da6fc2be547864451aa253836dd926da33623312df4a9a243e35dc877c378a78` |
| Architectures | Dockerfile supports `linux/amd64` and `linux/arm64`; CI publishes `linux/amd64` |
| Image size | ~4.0 GB |
| Container user | `root` |
| Locale | `C.UTF-8` |

---

## Compilers and toolchains

| Tool | Version | Source | Purpose |
| --- | --- | --- | --- |
| GCC / G++ | 15.2.0 | apt `g++-15` | Default host compiler; `gcc`/`g++`/`cc`/`c++`/`gcov` via update-alternatives |
| Clang / Clang++ | 22.1.2 | apt `clang-22` | Second host compiler, sanitizers, different diagnostics |
| LLD | 22.1.2 | apt `lld-22` | Fast linker (`-fuse-ld=lld`) |
| LLVM utilities | 22.1.2 | apt `llvm-22` | `llvm-objdump`, `llvm-readobj`, `llvm-cov`, `llvm-nm`, ... |
| mingw-w64 GCC | 13.2.0 (`posix` threads) | apt `gcc/g++-mingw-w64-x86-64-posix` | Linux → Windows x86_64 cross compilation |
| mingw-w64 runtime | 13.0.0 | apt `mingw-w64-x86-64-dev` | Windows headers and import libraries |
| mingw-w64 binutils | 2.45.90 | apt `binutils-mingw-w64-x86-64` | `windres`, `ar`, `objdump` for the Windows target |
| Arm GNU Toolchain | 15.2.rel1 (GCC 15.2.1) | binary, `/opt/gcc-arm-none-eabi` | ARM Cortex-M/R/A bare metal |
| NASM | 3.01 | apt | x86 assembly |

Only the **x86_64 POSIX** mingw variant is installed. The `win32` thread model has no
`std::thread`/`std::mutex`, and 32-bit Windows is out of scope.

`arm-none-eabi-gdb` and the toolchain `share/` tree are stripped to keep the image small:
`gdb-multiarch` debugs ARM targets just as well.

---

## Build systems and package managers

| Tool | Version | Source | Purpose |
| --- | --- | --- | --- |
| CMake | 4.4.3 | pip | Primary build system driver |
| Ninja | 1.13.2 | apt | Default generator (`CMAKE_GENERATOR=Ninja`) |
| Make | 4.4.1 | apt | Vendor SDKs that ship Makefiles |
| ccache | 4.13.1 | binary, minisign-verified | Compilation cache (`CCACHE_DIR=/cache/.ccache`) |
| Conan | 2.32.0 | pip | Package manager; default profile pre-detected, Ninja generator |
| CPM.cmake | 0.43.1 | binary, into the CMake module path | Dependency fetching without vendoring |
| Bear | 3.1.6 | apt | Generates `compile_commands.json` for non-CMake builds |
| pkgconf | 2.5.1 | apt | `pkg-config`; **required** for SDL/GTK feature detection |

---

## Debugging, analysis and coverage

| Tool | Version | Source | Purpose |
| --- | --- | --- | --- |
| GDB | 17.1 | apt | Host debugging |
| gdb-multiarch | 17.1 | apt | ARM and cross-target debugging |
| clangd | 22.1.2 | apt | IntelliSense, navigation, refactoring |
| clang-format | 22.1.2 | apt | Formatting |
| clang-tidy | 22.1.2 | apt | Static analysis and linting |
| clang-tools | 22.1.2 | apt | `scan-build`, `clang-check`, `clang-apply-replacements` |
| Valgrind | 3.26.0 | apt | Memory error and leak detection |
| Cppcheck | 2.19.0 | apt | Additional static analysis |
| gcovr | 8.6 | pip | Coverage reports from gcov |
| libclang-rt | 22.1.2 | apt | ASan / UBSan / TSan / MSan runtimes |

---

## Embedded development

| Tool | Version | Source | Purpose |
| --- | --- | --- | --- |
| OpenOCD | 0.12.0 | apt | Flashing and debugging via ST-Link, CMSIS-DAP, FTDI, J-Link |
| probe-rs | 0.32.0 | binary | Modern probe tooling with RTT and defmt support |
| QEMU (ARM) | 10.2.1 | apt `qemu-system-arm` | Run firmware without hardware |
| picocom | 3.1 | apt | Lightweight serial terminal |
| minicom | 2.10 | apt | Full-featured serial terminal |
| socat | 1.8.1.1 | apt | Serial/TCP bridging and virtual ports |
| dfu-util | 0.11 | apt | USB DFU flashing |
| usbutils | 019 | apt | `lsusb` for probe troubleshooting |
| SRecord | 1.64 | apt | `.hex` / `.bin` / `.srec` conversion |
| xsltproc | 1.1.45 | apt | SVD and vendor XML processing |
| libncurses-dev | 6.6 | apt | Required by OpenOCD/GDB TUI builds |

---

## Graphics, audio and input

Installed so SDL3, GLFW, Qt and similar frameworks detect every backend at configure time.
Verified with `pkg-config --modversion` in [test/smoke.sh](../test/smoke.sh).

| Group | Packages | Detected version |
| --- | --- | --- |
| X11 | `libx11-dev`, `libxext-dev`, `libxrandr-dev`, `libxcursor-dev`, `libxfixes-dev`, `libxi-dev`, `libxss-dev`, `libxtst-dev`, `libxkbcommon-dev` | x11 1.8.13, xkbcommon 1.13.1 |
| Wayland | `libwayland-dev`, `libdecor-0-dev` | wayland-client 1.24.0, libdecor 0.2.5 |
| OpenGL / EGL / GLES | `libgl-dev`, `libegl-dev`, `libgles-dev`, `libglu1-mesa-dev` | gl 1.2, egl 1.5, glesv2 3.2 |
| KMS / DRM | `libdrm-dev`, `libgbm-dev` | libdrm 2.4.131, gbm 26.0.8 |
| Vulkan | `libvulkan-dev`, `mesa-vulkan-drivers` | vulkan 1.4.341 |
| Software rendering | `libgl1-mesa-dri`, `libglx-mesa0` | OpenGL 4.5 via llvmpipe |
| Audio | `libasound2-dev`, `libpulse-dev`, `libpipewire-0.3-dev`, `libsndio-dev`, `libjack-jackd2-dev` | alsa 1.2.15, pulse 17.0, pipewire 1.6.2 |
| Input / IPC | `libudev-dev`, `libusb-1.0-0-dev`, `libdbus-1-dev`, `libibus-1.0-dev`, `liburing-dev` | udev 259, dbus 1.16.2 |
| Fonts and codecs | `libfreetype-dev`, `libharfbuzz-dev`, `libpng-dev`, `libjpeg-dev`, `zlib1g-dev` | freetype 2.14.2, harfbuzz 12.3.2 |
| X tooling | `x11-utils`, `mesa-utils`, `xvfb` | `xdpyinfo`, `glxinfo`, `xvfb-run` |

`xvfb` covers headless runs in CI: `xvfb-run -a ./my-app`.

---

## Dev container features

| Feature | Version | Provides |
| --- | --- | --- |
| `ghcr.io/devcontainers/features/desktop-lite` | 1.2.10 | Fluxbox + TigerVNC + noVNC. VNC on **5901**, browser desktop on **6080**, default password `vscode` |
| `ghcr.io/devcontainers/features/github-cli` | 1.1.2 | `gh` 2.101.0 |

Both are baked into the published image, so a consumer project only needs a `FROM` line.

---

## VS Code extensions

Pinned in [.devcontainer/devcontainer.json](../.devcontainer/devcontainer.json) and carried into
consumer projects through the `devcontainer.metadata` image label.

### Core C++

| Extension | Version | Why |
| --- | --- | --- |
| `llvm-vs-code-extensions.vscode-clangd` | 0.6.0 | IntelliSense, navigation, refactoring, inline clang-tidy |
| `ms-vscode.cpptools` | 1.34.4 | `cppdbg`/GDB debugging (IntelliSense disabled, clangd drives it) |
| `ms-vscode.cmake-tools` | 1.24.42 | Presets, configure, build, test and debug |
| `twxs.cmake` | 0.0.17 | `CMakeLists.txt` language support |
| `ms-vscode.makefile-tools` | 0.12.17 | Vendor SDKs that ship Makefiles |
| `usernamehw.errorlens` | 3.28.0 | Inline diagnostics |
| `ms-vscode.hexeditor` | 1.11.1 | Firmware and binary inspection |
| `matepek.vscode-catch2-test-adapter` | 4.26.0 | Test explorer for GoogleTest, Catch2 and doctest |
| `hediet.debug-visualizer` | 2.4.0 | Visualize buffers and data structures while debugging |

### Embedded

| Extension | Version | Why |
| --- | --- | --- |
| `marus25.cortex-debug` | 1.12.1 | ARM debugging through OpenOCD, probe-rs or J-Link |
| `mcu-debug.debug-tracker-vscode` | 0.0.15 | Shared debug session tracking for the `mcu-debug` set |
| `mcu-debug.memory-view` | 0.0.29 | Live memory windows |
| `mcu-debug.peripheral-viewer` | 1.6.4 | Peripheral registers from SVD files |
| `mcu-debug.rtos-views` | 0.0.16 | FreeRTOS / Zephyr thread inspection |
| `ms-vscode.vscode-serial-monitor` | 0.13.1 | UART console inside the editor |
| `zixuanwang.linkerscript` | 1.0.4 | `.ld` linker script syntax |
| `dan-c-underwood.arm` | 1.7.4 | ARM assembly syntax |
| `trond-snekvik.gnu-mapfiles` | 1.1.0 | `.map` file size analysis |

### Workflow

| Extension | Version | Why |
| --- | --- | --- |
| `mhutchie.git-graph` | 1.30.0 | Commit graph |
| `github.copilot` | 1.388.0 | Completions |
| `github.copilot-chat` | 0.48.1 | Chat and agent mode |
| `github.vscode-pull-request-github` | 0.166.1 | Pull requests and issues |
| `github.vscode-github-actions` | 0.32.3 | Workflow authoring |
| `ms-azuretools.vscode-docker` | 2.0.0 | Dockerfile and image management |
| `redhat.vscode-yaml` | 1.24.0 | Schema-aware YAML for CI files |

---

## Environment variables

| Variable | Value | Reason |
| --- | --- | --- |
| `CMAKE_GENERATOR` | `Ninja` | Ninja everywhere by default |
| `CMAKE_EXPORT_COMPILE_COMMANDS` | `On` | clangd always has a compilation database |
| `CMAKE_POLICY_VERSION_MINIMUM` | `3.5` | CMake 4 removed `< 3.5` compatibility, which vendored dependencies such as FreeType still declare |
| `CCACHE_DIR` | `/cache/.ccache` | Cache outside the image layers |
| `CPM_SOURCE_CACHE` | `/cache/.cpm` | Shared CPM download cache |
| `CONAN_HOME` | `/opt/conan` | Pre-detected Conan profile |
| `PYTHONPYCACHEPREFIX` | `/cache/.python` | Keeps `__pycache__` out of the workspace |
| `LANG` | `C.UTF-8` | Deterministic tool output |
| `PATH` | prefixed with `/usr/lib/llvm-22/bin` and `/opt/gcc-arm-none-eabi/bin` | Unsuffixed `clang`, `clangd`, `arm-none-eabi-*` |

`~/.cppdev/compile_commands.json` is seeded with `[]` so clangd works before the first
CMake configure; `cmake.copyCompileCommands` refreshes it afterwards.

---

## Known limitations

- **Windows target is capped at C++20 in practice.** Ubuntu 26.04 only ships GCC 13.2 for
  mingw-w64, so `<print>` and other C++23 library features are unavailable when cross
  compiling, even though the host compilers are GCC 15 / Clang 22.
- **`CMAKE_POLICY_VERSION_MINIMUM=3.5` is set globally.** It unblocks legacy dependencies but
  also hides deprecation warnings. Unset it per project once your dependencies are updated.
- **USB debug probes are not visible from a Windows host.** Docker Desktop cannot pass USB
  through; use [usbipd-win](https://github.com/dorssel/usbipd-win), or run the container on a
  Linux host and add `--device=/dev/bus/usb`.
- **No `wine`.** Cross-built `.exe` files cannot be smoke-tested in the container. Add
  `RUN apt-get install -y wine64` in your project Dockerfile if you need it (~1 GB).
- **32-bit Windows and non-ARM embedded targets are out of scope** (no i686 mingw, no ESP32,
  RISC-V, AVR or Pico toolchains).
