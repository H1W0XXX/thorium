# Thorium patches and platform profiles

The `other/` directory contains Thorium's Chromium patch files, x86 release
profiles, platform GN configurations, product metadata, and Linux package
wrappers.

## Patch series

The authoritative patch order and conditional entries are recorded in
[`patch_scripts/series/series`](../patch_scripts/series/series). Do not apply
the `*.patch` files alphabetically or infer ordering from their filenames.

[`docs/PATCHES.md`](../docs/PATCHES.md) documents patch ownership and origin.
The [rebasing guide](../docs/REBASING.md) describes dry-run application,
conditional entries, and safe patch refreshing.

## x86 release profiles

- [`SSE2`](SSE2/): 32-bit Linux and Windows SSE2 compatibility configurations;
- [`SSE3`](SSE3/): Linux x64 and Windows x86/x64 SSE3 configurations;
- [`SSE4.1`](SSE4.1/): Linux x64 and Windows x86/x64 SSE4.1 configurations;
- [`SSE4.2`](SSE4.2/): Linux x64 and Windows x86/x64 SSE4.2 configurations;
- [`AVX2`](AVX2/): Linux and Windows x64 `avx2_fma` configurations;
- [`AVX512`](AVX512/): Linux and Windows x64 `avx512_skx`
  configurations.

The ordinary root Linux and Windows args files select the AVX product profile.
The complete set of compiler profiles also includes `avx_fma` and the lower
`avx2` baseline for manual configurations.

`thorium_x86_profile` is the single source of truth for the process-wide C/C++
and Rust ISA requirement. Product labels, `thor_ver`, version-page text, and
Linux package wrappers are selected separately by the product mapping in
[`setup.py`](../setup.py).

Profiles use explicit feature flags rather than `-march` aliases that could
silently add AES, PCLMUL, BMI, LZCNT, POPCNT, or unrelated CPU capabilities.
Use [`check_simd.py`](../check_simd.py) and the
[release profile guide](../docs/ABOUT_RELEASES.md) instead of relying only on a
CPU family name.

## Platform configurations and metadata

- [`Mac`](Mac/) contains Intel x64 and Apple Silicon ARM64 macOS args;
- [`CrOS`](CrOS/) contains the x64 Linux-ChromeOS/ThoriumOS args;
- [`thor_ver_linux`](thor_ver_linux/) contains profile-specific Linux wrapper
  metadata used by `setup.py`.

Android, Raspberry Pi, and Windows on ARM64 configurations are maintained under
[`arm`](../arm/). General GN policy and configuration locations are documented
in [`docs/ABOUT_GN_ARGS.md`](../docs/ABOUT_GN_ARGS.md).
