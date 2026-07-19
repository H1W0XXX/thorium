# Thorium PAK Customizer

This directory vendors the Rust 3.x implementation of
[chrome-pak-customizer](https://github.com/myfreeer/chrome-pak-customizer) and
contains the prebuilt command-line tools bundled with Thorium desktop builds.
The pinned upstream revision and Thorium-specific integration details are
recorded in [`README.chromium`](README.chromium).

The tool unpacks and repacks Chromium PAK v4 and v5 files. It also supports
Brotli-compressed resources and the Microsoft Edge v5 resource-ID variant.

## Requirements

- Python 3.11 or newer
- Rust and Cargo
- The Rust target and native or cross-linker required by the selected platform

All Cargo operations use the checked-in lock file.

## Build

Build for the current Rust host target:

```bash
python3 pak_src/build.py build
```

Build a release target explicitly:

```bash
python3 pak_src/build.py build --target x86_64-unknown-linux-musl
```

Supported release targets are:

```text
x86_64-unknown-linux-musl
aarch64-unknown-linux-musl
x86_64-pc-windows-msvc
i686-pc-windows-msvc
x86_64-apple-darwin
aarch64-apple-darwin
```

GNU Linux host targets are also accepted for local compilation and testing,
but are not published into `binaries/`; Thorium's Linux prebuilts use musl to
avoid a dependency on the build host's glibc version.

## Test

Run the upstream Rust unit tests:

```bash
python3 pak_src/build.py test
```

Add one or more real Chromium/Thorium PAK files to perform byte-for-byte
round-trip checks:

```bash
python3 pak_src/build.py test \
  --fixture /path/to/resources.pak \
  --fixture /path/to/chrome_100_percent.pak
```

Fixtures are never downloaded automatically. If no explicit fixtures are
provided, the script uses `pak_src/tests/*.pak` when that directory exists.

## Publish Thorium prebuilts

`package` builds one target and atomically replaces its existing Thorium
integration binary together with `binaries/SHA256SUMS`:

```bash
python3 pak_src/build.py package --target x86_64-unknown-linux-musl
python3 pak_src/build.py package --target aarch64-unknown-linux-musl
python3 pak_src/build.py package --target x86_64-pc-windows-msvc
python3 pak_src/build.py package --target i686-pc-windows-msvc
```

For a release binary already built by an external cross-compilation command,
pass its explicit path with `--source`. The script verifies that its ELF or PE
architecture matches the requested target before publishing it. macOS targets
are build-only because Thorium does not currently bundle this utility in its
macOS application.

Publishing uses `binaries/.pak-build.lock/` to prevent concurrent processes
from replacing a binary and the shared checksum manifest at the same time. An
unclean process termination can leave this lock behind. Inspect its
`owner.txt`, confirm that the recorded process is no longer running on the
recorded host, and only then remove the lock directory manually. The script
never deletes an unknown stale lock automatically.

Published filenames intentionally remain compatible with the existing
`setup.py` and Windows installer integration during the migration:

```text
binaries/pak
binaries/pak_arm64
binaries/pak-win/pak_mingw32.exe
binaries/pak-win/pak_mingw64.exe
```

The Windows names are historical. They remain unchanged until newly generated
3.x binaries have passed real PAK round-trip and browser-loading validation.

### GitHub Actions

Maintainers who do not want to install cross-compilation toolchains locally
can run the manual `Build PAK 3.x binaries` workflow. It validates pinned PAK
fixtures, builds all four bundled targets in their appropriate hosted
environments, and performs a byte-identical PAK round trip with each generated
binary. It uploads `thorium-pak-3x-binaries` containing the binaries,
`SHA256SUMS`, file-type information, and per-platform toolchain records. Use
the included `thorium-pak-3x-binaries.tar.xz` when transferring the Linux
binaries because GitHub's expanded artifact view does not preserve executable
permission bits. The workflow creates this archive with normalized metadata,
then extracts it and verifies its exact contents, checksums, and Linux execute
permissions before upload. It never commits binaries or creates a GitHub
Release automatically.

## Clean

```bash
python3 pak_src/build.py clean
```

This command removes only `pak_src/target/`.

## Bundling

`setup.py` copies the appropriate Linux binary and the Windows helper files to
Chromium's `out/thorium` directory. The Windows mini installer then includes
the two Windows executables. Android builds do not bundle the PAK utility.

The legacy 2.0.2 C source and existing prebuilts remain temporarily available
as the migration safety baseline and remain covered by `LICENSE.legacy` and,
where applicable, `LICENSE.LGPL`. They must be removed only after all four new
release binaries have been built and validated against real M150 PAK files.
