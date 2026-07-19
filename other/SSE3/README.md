# Thorium SSE3

This directory contains Thorium SSE3 release configurations and product
metadata:

- [`args_SSE3.gn`](args_SSE3.gn): Linux x64;
- [`win32_SSE3_args.gn`](win32_SSE3_args.gn): Windows x86;
- [`win64_SSE3_args.gn`](win64_SSE3_args.gn): Windows x64.

The files select `thorium_x86_profile = "sse3"`. SSE3 is also Thorium's current
default compiler profile for ordinary x86 targets when no profile is selected.
It does not implicitly require SSSE3, SSE4, AVX, or AES. These supplied
low-baseline configurations also disable optional WebRTC AVX2 code.

Prepare the Chromium tree and SSE3 product metadata with:

```shell
python3 setup.py --sse3
```

`setup.py` does not install a GN args file. Review and use the file matching the
target platform and architecture, then run `gn gen out/thorium` from Chromium
`src`.

See [`check_simd.py`](../../check_simd.py) and the
[release profile guide](../../docs/ABOUT_RELEASES.md) for compatibility details.
