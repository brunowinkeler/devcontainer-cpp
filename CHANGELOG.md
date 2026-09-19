# Changelog

All notable changes to this image are documented here. Versions follow
[Semantic Versioning](https://semver.org/) and map 1:1 to the published image tags.

For this image the scheme means:

- **major** — base OS bump, compiler major bump, or removal of a tool;
- **minor** — new tools, new extensions, new features;
- **patch** — version bumps of existing tools, fixes, documentation.

## [1.0.0] - 2026-09-19

First versioned release. Rebuilt from scratch as a single batteries-included image covering
desktop graphics, embedded ARM and Windows cross compilation.

### Added

- Clang 22.1.2 toolchain: `clang`, `clang++`, `clangd`, `clang-format`, `clang-tidy`,
  `clang-tools`, `lld`, `llvm`, sanitizer runtimes. The image previously had no Clang at all.
- Full graphics stack so SDL3, GLFW and Qt detect every backend: X11, Wayland, OpenGL, EGL,
  GLES, Vulkan, KMS/DRM, ALSA, PulseAudio, PipeWire, JACK, sndio, udev, D-Bus, IBus.
- Mesa software rendering (`libgl1-mesa-dri`, `libglx-mesa0`, `mesa-vulkan-drivers`) plus
  `mesa-utils`, `x11-utils` and `xvfb` — OpenGL 4.5 works with no GPU.
- `desktop-lite` feature 1.2.10: Fluxbox, TigerVNC and noVNC on ports 5901 and 6080.
- Embedded tooling: OpenOCD 0.12.0, probe-rs 0.32.0, `qemu-system-arm` 10.2.1, `picocom`,
  `minicom`, `socat`, `dfu-util`, `usbutils`, SRecord.
- Analysis tooling: `gdb`, Valgrind 3.26.0, Cppcheck 2.19.0, Bear 3.1.6.
- `pkgconf` and `make`, both previously missing. Without `pkg-config` SDL silently disabled
  Wayland, libdecor, PulseAudio and PipeWire.
- 25 pinned VS Code extensions, carried into consumer projects through the
  `devcontainer.metadata` image label.
- `cmake/` examples: `toolchain-windows-mingw.cmake`, `toolchain-arm-none-eabi.cmake` and
  `CMakePresets-template.json`.
- `test/smoke.sh` and `test/presets.sh`, run by CI before every push.
- `docs/TOOLS.md` with the complete versioned inventory.

### Changed

- Base image from `ubuntu:24.04` to `ubuntu:26.04`, now digest-pinned.
- GCC 14 to GCC 15.2.0, CMake 4.1.0 to 4.4.3, Conan 2.20.1 to 2.32.0, gcovr 8.3 to 8.6,
  ccache 4.12 to 4.13.1, CPM 0.40.2 to 0.43.1, Arm GNU Toolchain 14.2 to 15.2.rel1.
- mingw-w64 now installs only the `x86_64` POSIX-thread variants. The `win32` thread model
  has no `std::thread`/`std::mutex`, and 32-bit Windows is out of scope.
- All external binaries are verified: `sha256` for the Arm toolchain, probe-rs and CPM,
  minisign for ccache.
- `CMAKE_POLICY_VERSION_MINIMUM=3.5` is exported so dependencies that still declare
  `cmake_minimum_required(VERSION 3.0...3.10)`, such as the FreeType vendored in SDL_ttf,
  configure under CMake 4.
- clangd drives IntelliSense; `ms-vscode.cpptools` is kept only as the debugger.

### Fixed

- `desktop-lite` and `github-cli` features were referenced with empty version tags,
  which made them invalid.

### Removed

- Cisco Umbrella root certificate and `NODE_EXTRA_CA_CERTS` — corporate leftovers from the
  repository this image was originally forked from.
- `libxinerama-dev` and `fcitx-libs-dev`: SDL3 uses neither.
