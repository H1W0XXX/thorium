# Thorium AVX2

This directory contains Thorium AVX2 release configurations and product
metadata:

- [`AVX2_args.gn`](AVX2_args.gn): Linux x64;
- [`win_AVX2_args.gn`](win_AVX2_args.gn): Windows x64.

Both release files select:

```gn
thorium_x86_profile = "avx2_fma"
```

This profile requires SSE3, AVX, AVX2, FMA, F16C, and operating-system AVX
state support. It does not implicitly require AES, PCLMUL, BMI/BMI2, LZCNT, or
POPCNT. The lower `avx2` GN profile remains available for manual compatibility
work, but `setup.py --avx2` and Thorium's supplied AVX2 release args use the
stricter `avx2_fma` product profile.

Prepare the Chromium tree and AVX2 product metadata from the Thorium repository
root with:

```shell
python3 setup.py --avx2
```

`setup.py` does not install either GN args file. Copy or review the matching
file as Chromium's `out/thorium/args.gn`, then run `gn gen out/thorium` from
Chromium `src`.

Use [`check_simd.py`](../../check_simd.py) before running the result. See the
[release profile guide](../../docs/ABOUT_RELEASES.md) and
[GN argument guide](../../docs/ABOUT_GN_ARGS.md) for the authoritative feature
matrix.

<img src="https://raw.githubusercontent.com/Alex313031/thorium/main/logos/STAGING/AVX2.png" alt="AVX2" width="86">
