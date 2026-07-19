# Thorium debugging infrastructure <img src="https://github.com/Alex313031/thorium/blob/main/logos/STAGING/bug.svg" alt="Debugging" width="28">

This directory contains maintained GN configurations, the cross-platform debug
build and packaging entry point, and resources for the Thorium UI Debug Shell.
All Python entry points require Python 3.11 or newer.

## Documentation

- [`ABOUT_GN_ARGS.md`](ABOUT_GN_ARGS.md) describes the maintained Debug,
  Release-with-DCHECK, and Release-with-symbols GN configurations.
- [`DEBUGGING.md`](DEBUGGING.md) covers configuration, building, packaging,
  logging, and current Chromium debugging references.
- [`DEBUG_SHELL_README.md`](DEBUG_SHELL_README.md) explains how to run, use,
  and build the Thorium UI Debug Shell.
- [`build_debug.py`](build_debug.py) is the authoritative build and packaging
  interface; run it with `--help` for all options.

## Supported workflow

| Platform | Maintained Debug configuration | Build | Portable Debug Shell package |
|---|---:|---:|---:|
| Linux x64 | Yes | Yes | Yes |
| Windows x64 | Yes | Yes | Yes |
| macOS x64 | Yes | Yes | No; use `--build-only` |
| macOS ARM64 | Yes | Yes | No; use `--build-only` |

The directory also contains Linux and Windows Release diagnostic GN examples.
They are not true Debug configurations and cannot be used with
`build_debug.py`, which requires `is_debug = true`.

After configuring `out/thorium` with a matching true Debug args file, a Linux
full build can be started from the Thorium repository root with:

```shell
python3 infra/DEBUG/build_debug.py --target-os linux --mode full
```

Use `--target-os win` on Windows. Use `--mode shell` to build and archive only
the standalone Debug Shell product. Detailed commands and output behavior are
documented in [`DEBUGGING.md`](DEBUGGING.md).

Debug products are development artifacts, not supported release installers.
Windows full mode still builds `setup` and `mini_installer` so those binaries
can be debugged; this does not make the resulting installer distributable.

<img src="https://github.com/Alex313031/thorium/blob/main/logos/NEW/thorium_infra_256.png" alt="Thorium infrastructure" width="200">
