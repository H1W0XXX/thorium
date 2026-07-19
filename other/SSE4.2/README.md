# Thorium SSE4.2

This directory contains Thorium SSE4.2 GN configurations and product metadata:

- [`args_SSE4.2.gn`](args_SSE4.2.gn): Linux x64;
- [`win32_SSE4.2_args.gn`](win32_SSE4.2_args.gn): Windows x86;
- [`win64_SSE4.2_args.gn`](win64_SSE4.2_args.gn): Windows x64.

The files select `thorium_x86_profile = "sse4_2"`, which requires SSE3, SSSE3,
SSE4.1, and SSE4.2. It does not implicitly require POPCNT, AVX, or AES. These
supplied configurations also disable optional WebRTC AVX2 code.

SSE4.2 is currently available as a manual GN profile, but `setup.py` does not
provide a dedicated SSE4.2 product selector. In particular,
`setup.py --sse4` selects SSE4.1 metadata and must not be described as an SSE4.2
setup command. Anyone publishing an SSE4.2 variant must explicitly keep its GN
configuration, version-page text, `thor_ver`, and package naming consistent.

Use [`check_simd.py`](../../check_simd.py) and consult the
[release profile guide](../../docs/ABOUT_RELEASES.md) before running the
result.
