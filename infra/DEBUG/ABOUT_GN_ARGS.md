# Diagnostic build GN arguments

The `.gn` files in this directory are maintained examples for true Debug,
Release-with-DCHECK, and Release-with-symbols builds. They contain intentional
Thorium policy overrides, not a complete list of Chromium GN arguments.

GN remains the source of truth for the arguments supported by the Chromium
revision being built. After generating an output directory, inspect an
argument with:

```shell
gn args out/thorium --list=ARGUMENT_NAME
```

Do not copy an args file to another operating system or CPU without reviewing
its platform values and minimum instruction-set requirement.

## Maintained configurations

| File | Configuration | Intended use | Minimum CPU profile |
|---|---|---|---|
| `linux_x64_debug_args.gn` | Linux x64 Debug | Source-level debugging and full symbols | AVX |
| `win_x64_debug_args.gn` | Windows x64 Debug | Source-level debugging and full symbols | SSE4.2 |
| `mac_x64_debug_args.gn` | macOS x64 Debug | Source-level debugging and full symbols | AVX2 + FMA |
| `mac_arm64_debug_args.gn` | macOS ARM64 Debug | Source-level debugging and full symbols | ARM64 |
| `linux_x64_release_dcheck_args.gn` | Linux x64 Release + DCHECK | Near-Release behavior with DCHECKs retained | AVX |
| `win_x64_release_dcheck_args.gn` | Windows x64 Release + DCHECK | Near-Release behavior with DCHECKs retained | SSE4.2 |
| `win_x64_release_symbols_args.gn` | Windows x64 Release + symbols | Crash and stack analysis with balanced symbols | AVX |

The CPU profiles are hard compatibility boundaries, not tuning hints. The
resulting executable must only be run on a processor satisfying the selected
profile.

## Compatibility with `build_debug.py`

[`build_debug.py`](build_debug.py) deliberately accepts only output directories
where:

```gn
is_debug = true
```

It can therefore be used with the four `*_debug_args.gn` configurations, but
not with `*_release_dcheck_args.gn` or `*_release_symbols_args.gn`. Build the
Release diagnostic configurations with the normal [`build.py`](../../build.py)
workflow or direct `autoninja` targets.

Linux and Windows Debug Shell packaging is currently defined only for x64.
macOS debug targets can be built, but their portable Debug Shell package layout
has not been defined and verified.

## Build identity and diagnostics

- `target_os`, `target_cpu`, and `v8_target_cpu` select the target platform.
- `is_debug = true` selects Chromium's true Debug configuration.
- `is_debug = false` with `dcheck_always_on = true` creates a Release
  diagnostic configuration rather than a Debug build.
- `is_official_build = false` identifies these as developer builds.
- `symbol_level`, `v8_symbol_level`, and `blink_symbol_level` control debug
  information. Higher levels increase build time, link memory, and output size.
- `is_component_build = false` produces the non-component layout expected by
  the Debug Shell packager.
- `enable_stripping = false` and `exclude_unwind_tables = false` preserve
  diagnostic information where supported.
- `use_debug_fission = true` uses split debug information on Linux.
- `enable_iterator_debugging` and `win_enable_cfg_guards` are Windows-specific
  diagnostic and security choices.
- `thorium_debug` controls Thorium's additional debug behavior where the
  corresponding patch is enabled.

## Optimization policy

True Debug configurations disable ThinLTO and its extra optimizations to keep
linking and debugging practical. Release DCHECK configurations may retain
ThinLTO because they are intended to behave more like optimized builds.

These local diagnostic configurations disable Chromium PGO with
`chrome_pgo_phase = 0`. `init_stack_vars_zero = false` is an explicit Thorium
policy choice with security implications and should not be copied into an
unrelated build without review.

`optimize_webui = false` keeps WebUI output easier to inspect where selected.
The maintained macOS Debug examples intentionally retain optimized WebUI
resources.

WebRTC's `rtc_enable_avx2` is not pinned here. Chromium can compile an optional
AVX2 implementation and select it at runtime; this does not replace or raise
the process-wide minimum ISA selected by `thorium_x86_profile`.

## Media and Widevine

The examples retain Thorium's supported media and WebRTC features. Actual
availability depends on the target platform, the applied patch series, and the
runtime hardware and operating system.

`enable_library_cdms` and `enable_widevine` enable library-CDM integration.
`bundle_widevine_cdm` separately controls whether a matching prebuilt payload
is included:

- Linux examples leave bundling disabled and can use an externally installed
  Widevine CDM.
- macOS examples bundle the matching repository payload.
- Windows examples leave bundling disabled.

These settings do not grant Widevine redistribution rights. They must remain
consistent with the payload available for the selected platform and CPU.

## Maintenance

When updating Chromium, run GN against every maintained args file. Remove
arguments that no longer exist, and remove overrides that merely duplicate an
upstream default unless they continue to express an intentional Thorium
policy. General Thorium GN policy is documented in
[`docs/ABOUT_GN_ARGS.md`](../../docs/ABOUT_GN_ARGS.md).
