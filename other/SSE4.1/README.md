# Thorium SSE4.1

This directory contains Thorium SSE4.1 release configurations and product
metadata:

- [`args_SSE4.1.gn`](args_SSE4.1.gn): Linux x64;
- [`win32_SSE4.1_args.gn`](win32_SSE4.1_args.gn): Windows x86;
- [`win64_SSE4.1_args.gn`](win64_SSE4.1_args.gn): Windows x64.

The files select `thorium_x86_profile = "sse4_1"`, which requires SSE3, SSSE3,
and SSE4.1. It does not implicitly require SSE4.2, POPCNT, AVX, or AES. These
supplied configurations also disable optional WebRTC AVX2 code.

Prepare the Chromium tree and SSE4.1 product metadata with:

```shell
python3 setup.py --sse4
```

The `--sse4` product selector intentionally means SSE4.1. It does not select
SSE4.2, and `setup.py` does not install a GN args file.

CPU generation names are only examples, not compatibility guarantees. Use
[`check_simd.py`](../../check_simd.py) and consult the
[release profile guide](../../docs/ABOUT_RELEASES.md) before running the
result.
