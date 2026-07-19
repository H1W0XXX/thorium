# Thorium GN arguments

<img src="https://raw.githubusercontent.com/Alex313031/Thorium/main/logos/NEW/GN_Light.svg#gh-dark-mode-only" alt="GN" width="36"> <img src="https://raw.githubusercontent.com/Alex313031/Thorium/main/logos/NEW/GN_Dark.svg#gh-light-mode-only" alt="GN" width="36">

GN generates Ninja build files from `args.gn`. Thorium's normal output
directory is `out/thorium`, but the name is not semantically significant.

```shell
cd /path/to/chromium/src
gn args out/thorium
gn args out/thorium --list
gn ls out/thorium
```

The `--list` output from the checked-out Chromium revision is authoritative for
all upstream arguments. This document describes Thorium-specific policy and
the arguments most likely to differ among Thorium configurations.

## API keys &nbsp;<img src="https://github.com/Alex313031/thorium/blob/main/logos/NEW/Key_Light.svg#gh-dark-mode-only" alt="API keys" width="26"> <img src="https://github.com/Alex313031/thorium/blob/main/logos/NEW/Key_Dark.svg#gh-light-mode-only" alt="API keys" width="26">&nbsp;

Generate and configure API keys and OAuth credentials by following Chromium's
[API Keys](https://www.chromium.org/developers/how-tos/api-keys/) procedure.
Do not commit private credentials to the repository.

## Configuration files

- [`args.gn`](../args.gn): normal Linux x64 release configuration.
- [`win_args.gn`](../win_args.gn): normal Windows x64 release configuration.
- [`other/Mac`](../other/Mac): Intel and Apple Silicon macOS configurations.
- [`other/AVX2`](../other/AVX2), [`other/AVX512`](../other/AVX512),
  [`other/SSE2`](../other/SSE2), [`other/SSE3`](../other/SSE3),
  [`other/SSE4.1`](../other/SSE4.1), and
  [`other/SSE4.2`](../other/SSE4.2): x86 compatibility and performance
  variants.
- [`arm`](../arm): Android, Raspberry Pi ARM64, and Windows ARM64.
- [`infra/DEBUG`](../infra/DEBUG): debug, diagnostic, and symbol-oriented
  configurations.

Copy one matching file into the GN editor. Do not merge multiple architecture
profiles, and keep the selected `setup.py` profile consistent with `args.gn`.

## Target and build mode

- `target_os` and `target_cpu` select the target platform and architecture.
- `v8_target_cpu` normally matches `target_cpu`.
- `is_official_build=true` enables Chromium's official-build policy and is
  used by release configurations.
- `is_debug`, `dcheck_always_on`, `symbol_level`, `v8_symbol_level`, and
  `blink_symbol_level` control debugging and symbols. Use the reviewed files in
  `infra/DEBUG` instead of improvising a hybrid release/debug configuration.
- `is_component_build=false` is used for normal distributable builds.
- `enable_stripping` and `exclude_unwind_tables` trade diagnostics for size;
  they differ in debug and platform-specific configurations.

## Thorium-specific build arguments

### `is_thorium_build`

Defined by Thorium's build patch and enabled by default. It marks the build as
Thorium for build-graph and branding decisions. It is not intended as a
complete switch for turning an overlaid source tree back into stock Chromium.

### `is_raspi`

Selects Thorium's Raspberry Pi ARM64 tuning. It is valid only for the reviewed
Linux ARM64 configuration and currently tunes generated code for Cortex-A72
without changing the ARM64 architectural baseline.

### `is_full_optimization_build`

Defaults to `is_official_build` and gates Thorium's release-oriented optimizer
policy. Debug and diagnostic builds should retain their reviewed settings.

### `thorium_x86_profile`

This is the canonical x86 ISA profile. It feeds C/C++, Rust, V8-linked targets,
installer CPU preflight metadata, and package naming. Supported values are:

| Profile | Required CPU capabilities | Tuning target |
| --- | --- | --- |
| `none` | No Thorium x86 ISA override | None |
| `sse2` | SSE2 | Baseline |
| `sse3` | SSE3 | Baseline |
| `sse4_1` | SSE3, SSSE3, SSE4.1 | Core 2 |
| `sse4_2` | SSE3, SSSE3, SSE4.1, SSE4.2 | Nehalem |
| `avx` | SSE3, AVX and OS AVX state support | Sandy Bridge |
| `avx_fma` | SSE3, AVX, FMA and OS AVX state support | AMD bdver2 |
| `avx2` | SSE3, AVX, AVX2 and OS AVX state support | Haswell |
| `avx2_fma` | SSE3, AVX, AVX2, FMA, F16C and OS AVX state support | Skylake |
| `avx512_skx` | AVX2/FMA/F16C plus AVX-512F/CD/VL/BW/DQ and OS state support | Skylake AVX-512 |

`-mtune` changes scheduling and code layout but does not itself add an ISA
requirement. The explicit profile feature list determines compatibility.
Validate a machine or an args file with:

```shell
python3 check_simd.py --profile avx2_fma
python3 check_simd.py --args-file /path/to/chromium/src/out/thorium/args.gn
```

The `setup.py --avx2` product profile currently selects `avx2_fma`; its name is
therefore broader than the exact CPU requirement. Always use `check_simd.py`.

## Optimization profiles

`chrome_pgo_phase` controls Chromium full PGO:

- `0`: no full PGO consumption;
- `1`: instrumentation build used to generate profile data;
- `2`: consume a downloaded profile.

`version.py` runs Chromium hooks. Those hooks require
`checkout_pgo_profiles=True` in the Chromium solution's `.gclient`
`custom_vars` for most desktop PGO profiles, Android AFDO, additional Android
PGO data, and V8 builtins profiles. Android ARM64 PGO is packaged with its
orderfile; Raspberry Pi currently uses `chrome_pgo_phase=0`.

Thorium release configurations commonly enable ThinLTO and optimized WebUI
resources. Do not assume a flag is universally safe merely because it appears
in one platform's args file; sanitizer, debug, ARM, and packaging configurations
may intentionally differ.

## Media and Widevine

Thorium configurations enable selected proprietary-codec and media patches.
Important arguments include `proprietary_codecs`, `ffmpeg_branding`,
`enable_ffmpeg_video_decoders`, `enable_platform_hevc`, and related platform
codec gates. Codec availability still depends on the platform implementation,
hardware, operating system, licenses, and website policy.

`enable_widevine` permits Widevine integration. `bundle_widevine_cdm` is
enabled only where a matching payload is available; Raspberry Pi uses external
CDM discovery instead. A bundled CDM does not imply Widevine VMP certification.
