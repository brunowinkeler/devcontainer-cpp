# syntax=docker/dockerfile:1

# Digest of ubuntu:26.04; bump it together with the apt-requirements-*.json pins.
ARG BASE_IMAGE=ubuntu:26.04@sha256:da6fc2be547864451aa253836dd926da33623312df4a9a243e35dc877c378a78

ARG ARM_GNU_TOOLCHAIN_VERSION=15.2.rel1
ARG CCACHE_MINISIGN_PUBKEY=RWQX7yXbBedVfI4PNx6FLdFXu9GHUFsr28s4BVGxm4BeybtnX3P06saF
ARG CCACHE_VERSION=4.13.1
ARG CPM_VERSION=0.43.1
ARG LLVM_MAJOR_VERSION=22
ARG LLVM_VERSION=22.1.2
ARG PROBE_RS_VERSION=0.32.0

FROM scratch AS downloader-amd64
ARG ARM_GNU_TOOLCHAIN_VERSION
ARG CCACHE_VERSION
ARG PROBE_RS_VERSION
ADD --checksum=sha256:597893282ac8c6ab1a4073977f2362990184599643b4c5ee34870a8215783a16 https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_GNU_TOOLCHAIN_VERSION}/binrel/arm-gnu-toolchain-${ARM_GNU_TOOLCHAIN_VERSION}-x86_64-arm-none-eabi.tar.xz /arm-gnu-toolchain.tar.xz
ADD --checksum=sha256:dd9fc188e738add3c12509063bb082b05e77a9a71fa85a20e01230044aa410f1 https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}-linux-x86_64-glibc.tar.xz /ccache.tar.xz
ADD --checksum=sha256:fdf00b1eadebf437e898ca3c0c94fd3e8d03b9e2bbe4f3d74ac6df2fecbf0a74 https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}-linux-x86_64-glibc.tar.xz.minisig /ccache.tar.xz.minisig
ADD --checksum=sha256:c2ccc46049e52a5d403ef212078cd637ecda55b662708327960558f83e851ff5 https://github.com/probe-rs/probe-rs/releases/download/v${PROBE_RS_VERSION}/probe-rs-tools-x86_64-unknown-linux-gnu.tar.xz /probe-rs.tar.xz

FROM scratch AS downloader-arm64
ARG ARM_GNU_TOOLCHAIN_VERSION
ARG CCACHE_VERSION
ARG PROBE_RS_VERSION
ADD --checksum=sha256:d061559d814b205ed30c5b7c577c03317ec447ca51cd5a159d26b12a5bbeb20c https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_GNU_TOOLCHAIN_VERSION}/binrel/arm-gnu-toolchain-${ARM_GNU_TOOLCHAIN_VERSION}-aarch64-arm-none-eabi.tar.xz /arm-gnu-toolchain.tar.xz
ADD --checksum=sha256:4cf4b05d9c381b3a60f1f10189f45ad9402bbc58979dbdc4901659c7f5e42dc8 https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}-linux-aarch64-glibc.tar.xz /ccache.tar.xz
ADD --checksum=sha256:24b50ebf8ce5ec9e5e56af298ddb17699a46f0d9bb035d7c824500270a5cde74 https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}-linux-aarch64-glibc.tar.xz.minisig /ccache.tar.xz.minisig
ADD --checksum=sha256:7c818cfd77808e806bf8f4d108c9137910b4fb28e0fe5c464d39782dbbc8af31 https://github.com/probe-rs/probe-rs/releases/download/v${PROBE_RS_VERSION}/probe-rs-tools-aarch64-unknown-linux-gnu.tar.xz /probe-rs.tar.xz

FROM downloader-${TARGETARCH} AS downloader
ARG CPM_VERSION
ADD --checksum=sha256:1c40fc102ce9625d7de7eb14f541cab30cc3138dca627f0b0ec40293ce6c2934 https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_VERSION}/CPM.cmake /CPM.cmake

FROM ${BASE_IMAGE} AS extractor

ARG CCACHE_MINISIGN_PUBKEY
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-Eeuo", "pipefail", "-c"]

RUN --mount=from=downloader,target=/src \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked <<EOT
apt-get update
apt-get install -y --no-install-recommends minisign xz-utils
minisign -P "${CCACHE_MINISIGN_PUBKEY}" -Vm /src/ccache.tar.xz -x /src/ccache.tar.xz.minisig
mkdir -p /out/bin /out/gcc-arm-none-eabi /tmp/probe-rs
tar -xJf /src/ccache.tar.xz --strip-components=1 -C /out/bin --wildcards '*/ccache'
# arm-none-eabi-gdb is dropped in favour of gdb-multiarch, share/ holds documentation only
tar -xJf /src/arm-gnu-toolchain.tar.xz --strip-components=1 -C /out/gcc-arm-none-eabi --exclude='*arm-none-eabi-gdb*' --exclude='share'
tar -xJf /src/probe-rs.tar.xz -C /tmp/probe-rs
find /tmp/probe-rs -type f -perm -u+x -exec install -m 0755 -t /out/bin {} +
cp /src/CPM.cmake /out/CPM.cmake
EOT

FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG LLVM_MAJOR_VERSION
ARG LLVM_VERSION

HEALTHCHECK NONE

# image.source links the GHCR package to this repository.
LABEL org.opencontainers.image.source="https://github.com/brunowinkeler/devcontainer-cpp" \
      org.opencontainers.image.description="Batteries-included C++ dev container: desktop graphics, embedded ARM and Windows cross compilation"

SHELL ["/bin/bash", "-Eeuo", "pipefail", "-c"]

ENV CCACHE_DIR=/cache/.ccache \
    CMAKE_EXPORT_COMPILE_COMMANDS=On \
    CMAKE_GENERATOR=Ninja \
    CONAN_HOME=/opt/conan \
    CPM_SOURCE_CACHE=/cache/.cpm \
    LANG=C.UTF-8 \
    PATH="/usr/lib/llvm-${LLVM_MAJOR_VERSION}/bin:/opt/gcc-arm-none-eabi/bin:${PATH}" \
    PYTHONPYCACHEPREFIX=/cache/.python

# CMake 4 removed compatibility with < 3.5, which many vendored dependencies still declare.
ENV CMAKE_POLICY_VERSION_MINIMUM=3.5

RUN --mount=type=bind,source=.devcontainer,target=/ctx \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/log,sharing=locked <<EOT
apt-get update
apt-get install -y --no-install-recommends jq
for group in base clang windows graphics embedded; do
  jq -r 'to_entries | .[] | .key + "=" + .value' "/ctx/apt-requirements-${group}.json" \
    | xargs apt-get install -y --no-install-recommends
done
sed -i '/^#\s*C\.UTF-8/s/^#\s*//' /etc/locale.gen
locale-gen
cp /etc/skel/.bashrc /root/.bashrc
EOT

RUN --mount=type=bind,source=.devcontainer,target=/ctx \
    --mount=type=bind,from=extractor,source=/out,target=/src \
    --mount=type=cache,target=/cache,sharing=locked \
    --mount=type=cache,target=/var/log,sharing=locked <<EOT
install -m 0755 -t /usr/local/bin /src/bin/*
cp -a /src/gcc-arm-none-eabi /opt/gcc-arm-none-eabi

# --ignore-installed: apt ships python3-pygments (a gdb dependency) without a RECORD file,
# so pip cannot uninstall it when resolving the gcovr dependency tree.
python3 -m pip install --break-system-packages --ignore-installed --require-hashes --no-cache-dir --no-compile -r /ctx/requirements.txt
find / -regex '^.*\(__pycache__\|\.py[co]\)$' -delete || true
rm -rf "$(pip cache dir)"

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 10 \
                    --slave /usr/bin/g++ g++ /usr/bin/g++-15 \
                    --slave /usr/bin/gcov gcov /usr/bin/gcov-15
update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-15 10 \
                    --slave /usr/bin/c++ c++ /usr/bin/g++-15
update-alternatives --install /usr/bin/python python /usr/bin/python3 10

# The win32 thread model lacks std::thread/std::mutex, which SDL, spdlog and friends need.
update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix
update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix

actual_llvm="$(clang --version | sed -nE 's/.*clang version ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' | head -n1)"
if [[ "${actual_llvm}" != "${LLVM_VERSION}" ]]; then
  echo "error: expected clang ${LLVM_VERSION}, found ${actual_llvm:-none}" >&2
  exit 1
fi

# Makes CPM available to every project without vendoring it.
cp /src/CPM.cmake /usr/local/lib/python*/dist-packages/cmake/data/share/cmake-*/Modules/

conan profile detect
printf '\n[conf]\ntools.cmake.cmaketoolchain:generator=Ninja\n' >> "$(conan profile path default)"

# clangd needs a compilation database before the first CMake configure.
mkdir -p /root/.cppdev
echo '[]' > /root/.cppdev/compile_commands.json
EOT
