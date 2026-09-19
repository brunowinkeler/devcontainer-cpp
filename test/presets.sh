#!/usr/bin/env bash
# Configures and builds the smoke workspace with every preset shipped in cmake/.
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/workspace"
rm -rf build

for preset in linux-debug linux-clang-debug windows-mingw-release arm-none-eabi-release; do
  echo "::: ${preset}"
  cmake --preset "${preset}" >/dev/null
  cmake --build --preset "${preset}" >/dev/null
  artifact="$(find "build/${preset}" -maxdepth 1 -name 'smoke*' -type f)"
  printf '  %-24s %s\n' "${preset}" "$(file -b "${artifact}" | cut -d, -f1-2)"
done

echo "::: compilation database"
test -s build/linux-debug/compile_commands.json && echo "  compile_commands.json generated"
