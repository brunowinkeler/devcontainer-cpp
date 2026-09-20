#!/usr/bin/env bash
set -uo pipefail

echo "=== versions ==="
for c in "gcc --version" "g++ --version" "clang --version" "clang++ --version" \
         "clangd --version" "clang-format --version" "clang-tidy --version" "ld.lld --version" \
         "cmake --version" "ninja --version" "conan --version" "gcovr --version" "ccache --version" \
         "gdb --version" "gdb-multiarch --version" "arm-none-eabi-gcc --version" \
         "x86_64-w64-mingw32-g++ --version" "openocd --version" "probe-rs --version" \
         "qemu-system-arm --version" "pkg-config --version" "valgrind --version" \
         "cppcheck --version" "bear --version" "picocom --help" "socat -V" "dfu-util --version"; do
  name="${c%% *}"
  out="$($c 2>&1 | head -n1)"
  printf '%-24s %s\n' "$name" "${out:-<none>}"
done

echo
echo "=== mingw thread model ==="
x86_64-w64-mingw32-g++ -v 2>&1 | grep -i 'thread model'

echo
echo "=== compile smoke tests ==="
cat > /tmp/t.cpp <<'CPP'
#include <print>
int main() { std::print("ok\n"); return 0; }
CPP
g++ -std=c++23 /tmp/t.cpp -o /tmp/t.native && echo "native g++:   $(file -b /tmp/t.native | cut -d, -f1-2)"
clang++ -std=c++23 -stdlib=libstdc++ /tmp/t.cpp -o /tmp/t.clang && echo "native clang: $(file -b /tmp/t.clang | cut -d, -f1-2)"

# The Ubuntu mingw cross compiler is GCC 13, so C++20 is the practical ceiling for Windows.
cat > /tmp/w.cpp <<'CPP'
#include <format>
#include <iostream>
#include <mutex>
int main() { std::mutex m; std::lock_guard g{m}; std::cout << std::format("ok\n"); return 0; }
CPP
x86_64-w64-mingw32-g++ -std=c++20 -static /tmp/w.cpp -o /tmp/t.exe && echo "mingw:        $(file -b /tmp/t.exe | cut -d, -f1-2)"

cat > /tmp/a.c <<'C'
int main(void) { return 0; }
C
arm-none-eabi-gcc -mcpu=cortex-m4 -nostartfiles -nostdlib -Wl,-e,main /tmp/a.c -o /tmp/a.elf \
  && echo "arm-none-eabi: $(readelf -h /tmp/a.elf | awk -F: '/Machine/{print $2}' | xargs)"

echo
echo "=== SDL3 feature detection deps ==="
for m in x11 xext xrandr xcursor xi xfixes xkbcommon wayland-client libdecor-0 gl egl glesv2 libdrm gbm alsa libpulse libpipewire-0.3 libudev dbus-1 vulkan; do
  printf '%-18s %s\n' "$m" "$(pkg-config --modversion "$m" 2>/dev/null || echo MISSING)"
done

echo
echo "=== headless OpenGL ==="
xvfb-run -a glxinfo -B 2>/dev/null | grep -E 'OpenGL (vendor|renderer|version) string' || echo "glxinfo FAILED"

echo
echo "=== desktop-lite ==="
for b in vncserver Xtigervnc fluxbox; do printf '%-12s %s\n' "$b" "$(command -v "$b" || echo MISSING)"; done
printf '%-12s %s\n' "noVNC" "$([ -d /usr/local/novnc ] && echo /usr/local/novnc || echo MISSING)"
printf '%-12s %s\n' "desktop-init" "$(ls /usr/local/share/desktop-init.sh 2>/dev/null || echo MISSING)"

echo
echo "=== CPM + conan ==="
ls /usr/local/lib/python*/dist-packages/cmake/data/share/cmake-*/Modules/CPM.cmake
grep -A1 '\[conf\]' /opt/conan/profiles/default
cat /root/.cppdev/compile_commands.json

echo
echo "=== tool inventory ==="
inventory="$(dirname "${BASH_SOURCE[0]}")/tool-inventory.json"
missing=0

while read -r tool; do
  # Package names rarely match the binary they install.
  case "${tool}" in
  arm-gnu-toolchain) binary=arm-none-eabi-gcc ;;
  binutils-mingw-w64-x86-64) binary=x86_64-w64-mingw32-objdump ;;
  clang-tools-22) binary=scan-build ;;
  clang-22 | clang-format-22 | clang-tidy-22 | clangd-22) binary="${tool%-22}" ;;
  g++-15) binary=g++ ;;
  g++-mingw-w64-x86-64-posix) binary=x86_64-w64-mingw32-g++ ;;
  gcc-mingw-w64-x86-64-posix) binary=x86_64-w64-mingw32-gcc ;;
  lld-22) binary=ld.lld ;;
  llvm-22) binary=llvm-objdump ;;
  mesa-utils) binary=glxinfo ;;
  ninja-build) binary=ninja ;;
  pkgconf) binary=pkg-config ;;
  srecord) binary=srec_cat ;;
  usbutils) binary=lsusb ;;
  xvfb) binary=Xvfb ;;
  *) binary="${tool}" ;;
  esac

  if ! command -v "${binary}" >/dev/null 2>&1; then
    printf '  %-28s MISSING (looked for %s)\n' "${tool}" "${binary}"
    missing=$((missing + 1))
  fi
done < <(jq -r '.[]' "${inventory}")

if [ "${missing}" -eq 0 ]; then
  printf '  all %s tools present\n' "$(jq -r 'length' "${inventory}")"
else
  printf '  %s tool(s) missing\n' "${missing}"
fi

exit "${missing}"
