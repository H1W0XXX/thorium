# Thorium for macOS

This directory contains the maintained Thorium macOS Release configurations:

- [`mac_args.gn`](mac_args.gn): Intel x64 using the `avx2_fma` profile;
- [`mac_ARM_args.gn`](mac_ARM_args.gn): Apple Silicon ARM64.

Both configurations use the system Xcode toolchain and Chromium PGO. The
Chromium checkout must therefore have the required PGO profiles available, as
described in the [macOS build guide](../../docs/BUILDING_MAC.md).

Prepare the Chromium tree and macOS product metadata from the Thorium
repository root with:

```shell
python3 setup.py --mac
```

The same setup selector is used for both CPU architectures. It does not choose
or install a GN args file; use the matching file above as Chromium's
`out/thorium/args.gn`, then run:

```shell
gn gen out/thorium
python3 /path/to/thorium/build.py \
  --chromium-src /path/to/chromium/src --expect-os mac
```

After a successful build, use `create_dmg.py` from the Thorium repository to
create the DMG. When updating the macOS application icon, follow the
[layered icon generation guide](../../logos/NEW/mac/gen/README.md) so
`Assets.car` and `app.icns` remain synchronized.

<img src="https://raw.githubusercontent.com/Alex313031/thorium/main/logos/STAGING/Happy_Mac.svg" alt="Happy Mac" width="100">
