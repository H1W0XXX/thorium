# Thorium SSE2

This directory contains Thorium's explicitly maintained 32-bit SSE2
compatibility configuration:

- [`args_SSE2.gn`](args_SSE2.gn): Linux x86;
- [`win32_SSE2_args.gn`](win32_SSE2_args.gn): Windows x86.

Both files select `thorium_x86_profile = "sse2"`. The central compiler profile
owns the ISA flags and does not implicitly add SSE3 or later instruction sets.

Prepare this variant from the Thorium repository root with:

```shell
python3 setup.py --sse2
```

This selector also enables the series' `sse2` condition, including
[`angle-lockfree.patch`](angle-lockfree.patch), and selects the matching
version and packaging metadata. It does not install a GN args file.

Chromium no longer officially supports 32-bit Linux. The Linux args therefore
disable Chromium PGO and represent a Thorium compatibility configuration, not
a promise of support equivalent to current x64 builds.

Use [`check_simd.py`](../../check_simd.py) to check the CPU before running the
result. See the [release profile guide](../../docs/ABOUT_RELEASES.md) for the
central feature matrix.
