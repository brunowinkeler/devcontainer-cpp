# syntax=docker/dockerfile:1

FROM ubuntu:24.04 AS extractor

ARG CCACHE_VERSION=4.12
ARG CPM_VERSION=0.40.2

ARG DEBIAN_FRONTEND=noninteractive

HEALTHCHECK NONE

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set default environment options
ENV CCACHE_DIR=/cache/.ccache \
    CMAKE_EXPORT_COMPILE_COMMANDS="On" \
    CMAKE_GENERATOR="Ninja" \
    CONAN_HOME=/opt/conan \
    CPM_SOURCE_CACHE=/cache/.cpm \
    PATH="$PATH:/opt/gcc-arm-none-eabi/bin" \
    PYTHONPYCACHEPREFIX=/cache/.python

# Install the base system with all tool dependencies
# hadolint ignore=DL3008
RUN --mount=type=bind,source=.devcontainer/apt-requirements-base.json,target=/tmp/apt-requirements-base.json \
    --mount=type=bind,source=.devcontainer/requirements.txt,target=/tmp/requirements.txt \
    --mount=type=cache,target=/cache,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/log,sharing=locked \
 apt-get update && apt-get install -y --no-install-recommends jq \
 && jq -r 'to_entries | .[] | .key + "=" + .value' /tmp/apt-requirements-base.json | \
    xargs apt-get install -y --no-install-recommends \
 # Include the Cisco Umbrella PKI Root
 && wget --no-hsts -qO /usr/local/share/ca-certificates/Cisco_Umbrella_Root_CA.crt https://www.cisco.com/security/pki/certs/ciscoumbrellaroot.pem \
 && update-ca-certificates \
 # Install some tools via pip to get more recent versions, clean up afterwards
 && python3 -m pip install --break-system-packages --require-hashes --no-cache-dir --no-compile -r /tmp/requirements.txt \
 && find / -regex '^.*\(__pycache__\|\.py[co]\)$' -delete \
 && rm -rf "$(pip cache dir)"

# Install arm-gcc toolchain
RUN mkdir /opt/gcc-arm-none-eabi \
 && wget --no-hsts -qO - "https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-$(uname -m)-arm-none-eabi.tar.xz" | tar --exclude='*arm-none-eabi-gdb*' --exclude='share' --strip-components=1 -xJC /opt/gcc-arm-none-eabi

# Install ccache
RUN wget --no-hsts -qO - "https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}-linux-$(uname -m).tar.xz" | tar -xJ -C /usr/local/bin --strip-components=1 "ccache-${CCACHE_VERSION}-linux-$(uname -m)/ccache"

# Update all tool alternatives to the correct version
# and patch root's bashrc to include bash-completion
RUN --mount=type=cache,target=/var/log,sharing=locked \
 update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 10 \
                        --slave /usr/bin/g++ g++ /usr/bin/g++-14 \
                        --slave /usr/bin/gcov gcov /usr/bin/gcov-14 \
 && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-14 10 \
                        --slave /usr/bin/c++ c++ /usr/bin/g++-14 \
 && update-alternatives --install /usr/bin/python python /usr/bin/python3 10 \
 && cp /etc/skel/.bashrc /root/.bashrc

# Set up package managers CPM and Conan
# - Install CPM.cmake to the CMake module path
# - Configure a default profile for Conan and set the CMake generator to Ninja
RUN --mount=type=cache,target=/cache,sharing=locked \
 wget --no-hsts -qP /usr/local/lib/python*/dist-packages/cmake/data/share/cmake-*/Modules/ https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_VERSION}/CPM.cmake \
 && conan profile detect \
 && echo -e "\n[conf]\ntools.cmake.cmaketoolchain:generator=Ninja" >> "$(conan profile path default)"
