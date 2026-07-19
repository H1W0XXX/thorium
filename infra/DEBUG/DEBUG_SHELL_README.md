# Thorium UI Debug Shell <img src="https://raw.githubusercontent.com/Alex313031/Thorium/main/logos/NEW/thorium_debug_shell/icon_256.png" alt="Thorium UI Debug Shell" width="36">

The Thorium UI Debug Shell is a standalone inspection tool built from
Chromium's Views examples with content-shell support. It can display and test
native UI controls, resources, and Chromium `.icon` vector files without
running the full browser UI.

Some examples are interactive, some use compiled resources, and others accept
an external file. When an example requests a file, enter its full path in the
file field near the bottom of the window.

## Run a packaged shell

On Linux, run the wrapper from the extracted package:

```shell
./Thorium_Debug_Shell.sh
```

The wrapper configures the package-local library path and starts
`thorium_ui_debug_shell --debug` while preserving additional command-line
arguments.

On Windows, run:

```text
thorium_ui_debug_shell.exe
```

macOS Debug Shell targets can currently be built, but Thorium does not yet
publish a verified portable package layout for them.

## Inspect Thorium vector icons

The following paths are relative to Chromium `src`:

- `ui/views/vector_icons/`: native Views UI icons;
- `ui/views/window/vector_icons/`: window and top-bar icons;
- `components/vector_icons/`: icons shared by multiple components;
- `chrome/app/vector_icons/`: browser-specific icons;
- `ash/resources/vector_icons/`: Ash and ChromiumOS icons;
- `chromeos/ui/vector_icons/`: ChromiumOS-specific UI icons;
- `chromecast/ui/vector_icons/`: Chromecast-specific icons.

See Chromium's [vector icon documentation](https://chromium.googlesource.com/chromium/src/+/HEAD/components/vector_icons/README.md)
for the source format and generation rules.

## Build <img src="https://github.com/Alex313031/thorium/blob/main/logos/NEW/build_light.svg#gh-dark-mode-only" alt="Build" width="36"> <img src="https://github.com/Alex313031/thorium/blob/main/logos/NEW/build_dark.svg#gh-light-mode-only" alt="Build" width="36">

From the Thorium repository root, build the full Linux Debug product set and
assemble the Debug Shell directory:

```shell
python3 infra/DEBUG/build_debug.py --target-os linux --mode full
```

Use `--target-os win` on Windows. Full mode creates the package directory but
does not create a ZIP archive.

To build only the Debug Shell support targets and create both the package
directory and ZIP archive, use:

```shell
python3 infra/DEBUG/build_debug.py --target-os linux --mode shell
```

Linux shell-only mode also includes `minidump_stackwalk`, `dump_syms`, and the
ClearKey CDM payload. Pass `-j N` to limit parallel jobs. On macOS, append
`--build-only` because packaging is not currently supported.

For configuration, output locations, and other modes, see
[`DEBUGGING.md`](DEBUGGING.md).
