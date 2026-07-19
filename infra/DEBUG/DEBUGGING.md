# Debugging Thorium

Thorium uses Chromium's debugging facilities. This page describes the
Thorium-specific setup and points to the current upstream debugging manuals.

## Prerequisites

- Python 3.11 or newer;
- a prepared Chromium source checkout with the Thorium patch series applied;
- `gn` and `autoninja` from `depot_tools` available in `PATH`;
- a host matching the requested target OS.

`build_debug.py` locates Chromium through `--chromium-src`, then `CR_DIR`, and
finally its platform default. It locates Thorium through `--thorium-root`, then
`THOR_DIR`, and finally this repository. Its default GN output directory is
`out/thorium` under Chromium `src`.

## Configure a true Debug build

Choose a matching `*_debug_args.gn` file from this directory and use its
contents as the Chromium output directory's `args.gn`. For example, on Linux
from the Thorium repository root:

```shell
cp infra/DEBUG/linux_x64_debug_args.gn \
  /path/to/chromium/src/out/thorium/args.gn
cd /path/to/chromium/src
gn gen out/thorium
```

On Windows PowerShell:

```powershell
Copy-Item "$HOME\thorium\infra\DEBUG\win_x64_debug_args.gn" `
  "C:\src\chromium\src\out\thorium\args.gn"
Set-Location "C:\src\chromium\src"
gn gen out/thorium
```

Review an existing `args.gn` before overwriting it. The four true Debug files
are listed in [`ABOUT_GN_ARGS.md`](ABOUT_GN_ARGS.md). Release-with-DCHECK and
Release-with-symbols files are diagnostic Release configurations and are not
accepted by `build_debug.py`.

## Build and package

From the Thorium repository root, build the maintained Debug target set and
assemble the Linux Debug Shell directory with:

```shell
python3 infra/DEBUG/build_debug.py --target-os linux --mode full
```

Use `--target-os win` on Windows. Linux and Windows packaging is defined only
for x64. macOS currently supports build-only operation:

```shell
python3 infra/DEBUG/build_debug.py \
  --target-os mac --mode full --build-only
```

Important operation modes:

- `--mode full` builds Thorium's full maintained debug product set and, on
  Linux or Windows, assembles the Debug Shell directory.
- `--mode shell` builds only the Debug Shell support targets, assembles the
  directory, and creates `Thorium_UI_Debug_Shell.zip`.
- `--build-only` builds without packaging.
- `--package-only` packages existing Linux or Windows x64 artifacts without
  invoking `autoninja`.
- `--dry-run` validates the configuration and prints the build commands.
- `--single-pass` intentionally places all selected targets in one
  `autoninja` invocation; the default builds them in separate phases.

Use `-C PATH` to select another GN output directory and `-j N` to limit build
parallelism. Run `python3 infra/DEBUG/build_debug.py --help` for the complete
interface.

Packaged outputs are placed under the selected GN output directory:

```text
Thorium_UI_Debug_Shell/
Thorium_UI_Debug_Shell.zip  # shell mode only
```

## Runtime logging

Useful Chromium switches include:

```text
--enable-logging=stderr
--v=1
--vmodule=source_file=2
```

Thorium's debug-mode support also recognizes the `THORIUM_DEBUG` environment
variable when the corresponding patch is enabled.

## Upstream documentation

Debugging behavior changes frequently, so Thorium does not duplicate the full
Chromium manuals:

- [Cross-platform debugging](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/debugging.md)
- [Linux debugging](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/linux/debugging.md)
- [macOS debugging](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/mac/debugging.md)
- [Android debugging](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/android_debugging_instructions.md)
- [Logging](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/logging.md)
- [Profiling](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/profiling.md)

When `HEAD` differs, follow the documentation matching the Chromium revision
used by the current Thorium branch.
