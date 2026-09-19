# devcontainer-cpp

A batteries-included C++ dev container for the three things I actually build:

- **desktop applications with graphics** — SDL3, OpenGL, Vulkan, Wayland and X11 all detected out of the box, with a browser-accessible desktop so GUI apps can be previewed;
- **embedded firmware** — Arm GNU Toolchain, OpenOCD, probe-rs, QEMU and serial tooling;
- **Windows builds from Linux** — mingw-w64 cross compilation producing a single static `.exe`.

The full inventory, with versions and rationale, lives in [docs/TOOLS.md](docs/TOOLS.md).

## Using it in a project

Create `.devcontainer/Dockerfile`:

```dockerfile
FROM ghcr.io/brunowinkeler/devcontainer-cpp:1.0.0
HEALTHCHECK NONE
```

and `.devcontainer/devcontainer.json`:

```json
{
  "build": { "dockerfile": "Dockerfile" }
}
```

That is all. Extensions, editor settings, the noVNC desktop and port forwarding are baked
into the image as a `devcontainer.metadata` label and inherited automatically.

A `Dockerfile` is preferred over `"image"` so Dependabot can bump the `FROM` line.

## Versioning

Releases are semantic versions driven by git tags. Pushing `vX.Y.Z` publishes four tags:

| Tag | Moves | Use when |
| --- | --- | --- |
| `1.2.3` | never | You want a byte-identical environment forever |
| `1.2` | on every patch | You want tool bugfixes but no new tools |
| `1` | on every minor | You want new tools but no breaking changes |
| `latest` | on every release | You do not care |
| `edge` | every push to `main` | You want to try unreleased changes |

What each level means for this image:

- **major** — base OS bump, compiler major bump, or a tool removed;
- **minor** — new tools, extensions or features;
- **patch** — version bumps of existing tools, fixes, documentation.

Older versions stay in the registry, so rolling a project back is just editing its `FROM`
line. [CHANGELOG.md](CHANGELOG.md) records what changed in each release, and every release
links the `docs/TOOLS.md` captured at that tag.

Cutting a release:

```bash
git tag v1.1.0
git push origin v1.1.0
```

CI builds the image, runs both verification scripts, pushes the four tags and opens a
GitHub release. Nothing is published if the verification fails.

To let Dependabot keep a consuming project up to date, add `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: docker
    directory: .devcontainer
    schedule:
      interval: weekly
```

## Previewing graphical applications

The `desktop-lite` feature runs Fluxbox behind TigerVNC and noVNC:

| Port | What |
| --- | --- |
| 6080 | noVNC — open `http://localhost:6080` in a browser |
| 5901 | plain VNC, for a native client |

Default password is `vscode`. Run your app with `DISPLAY=:1`, which is already exported.
Rendering goes through Mesa `llvmpipe`, so OpenGL 4.5 works without a GPU.

For headless runs, for example in CI, use `xvfb-run -a ./my-app`.

## Cross-compiling to Windows

Copy [cmake/toolchain-windows-mingw.cmake](cmake/toolchain-windows-mingw.cmake) into your
project and take the presets you need from
[cmake/CMakePresets-template.json](cmake/CMakePresets-template.json):

```bash
cmake --preset windows-mingw-release
cmake --build --preset windows-mingw-release
```

The toolchain links statically, so the result is a self-contained `.exe` with no
`libgcc`/`libstdc++`/`libwinpthread` DLLs to ship.

The container has no `wine`, so the executable cannot be run here — copy it to a Windows
host to test.

## Embedded targets

[cmake/toolchain-arm-none-eabi.cmake](cmake/toolchain-arm-none-eabi.cmake) is a starting
point for Cortex-M; adjust `ARM_CPU_FLAGS` to your MCU. `cortex-debug` is pre-configured to
use `gdb-multiarch` and `openocd`.

USB probes are **not** reachable from a Windows host: Docker Desktop has no USB passthrough.
Either use [usbipd-win](https://github.com/dorssel/usbipd-win), or run the container on a
Linux host and add to `devcontainer.json`:

```json
{
  "runArgs": ["--device=/dev/bus/usb"]
}
```

`qemu-system-arm` lets you run and debug firmware with no hardware at all.

## Building the image locally

Features have to be baked in, so build through the dev container CLI rather than
`docker build`:

```bash
npx --yes @devcontainers/cli build --workspace-folder . --image-name devcontainer-cpp:local
```

Then verify it:

```bash
docker run --rm -v "$PWD:/w" -w /w devcontainer-cpp:local bash test/smoke.sh
docker run --rm -v "$PWD:/w" -w /w devcontainer-cpp:local bash test/presets.sh
```

`smoke.sh` reports every tool version and compiles for all three targets.
`presets.sh` configures and builds [test/workspace](test/workspace) with each shipped preset
and checks that the produced binaries are really ELF, PE32+ and ARM ELF.

## Updating pinned versions

Everything is pinned on purpose. To bump:

- **apt packages** — edit the `apt-requirements-*.json` files. Resolve current versions with
  `apt-cache policy <pkg>` inside `ubuntu:26.04`.
- **Python tools** — edit `requirements.in`, then regenerate the hashes with
  `pip-compile --generate-hashes requirements.in`.
- **Binaries** (ccache, CPM, probe-rs, Arm GNU Toolchain) — edit the `ARG`s at the top of the
  Dockerfile together with their `--checksum=sha256:` values.
- **Extensions and features** — edit `.devcontainer/devcontainer.json`.

Then rebuild, update [docs/TOOLS.md](docs/TOOLS.md), add a [CHANGELOG.md](CHANGELOG.md)
entry and tag the release.

