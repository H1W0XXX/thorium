# Thorium releases and CPU variants

Thorium provides platform and CPU-specific builds. An x86 binary compiled for
an unsupported instruction profile can fail before the browser starts, so the
variant name must be treated as a minimum requirement rather than a marketing
label.

## x86 SIMD profiles

The current build system understands these profiles:

| Profile | Minimum capabilities checked by Thorium | Typical platform examples |
| --- | --- | --- |
| `sse2` | SSE2 | Intel Pentium 4 and AMD Athlon 64 families or newer |
| `sse3` | SSE3 | Later Pentium 4, Intel Core, and SSE3-capable AMD K8/K10 families or newer |
| `sse4_1` | SSE3, SSSE3, SSE4.1 | Intel Penryn and AMD Bulldozer families or newer |
| `sse4_2` | SSE3, SSSE3, SSE4.1, SSE4.2 | Intel Nehalem and AMD Bulldozer families or newer |
| `avx` | SSE3, AVX and operating-system AVX state support | Intel Sandy Bridge and AMD Bulldozer families or newer |
| `avx_fma` | SSE3, AVX, FMA and operating-system AVX state support | Intel Haswell and AMD Piledriver families or newer |
| `avx2` | SSE3, AVX, AVX2 and operating-system AVX state support | Intel Haswell and AMD Excavator/Zen families or newer |
| `avx2_fma` | SSE3, AVX, AVX2, FMA, F16C and operating-system AVX state support | Intel Haswell and AMD Excavator/Zen families or newer |
| `avx512_skx` | AVX2/FMA/F16C, AVX-512F/CD/VL/BW/DQ and operating-system state support | Selected Intel Skylake-SP and Skylake-X processors with the complete required AVX-512 subset |

These examples identify common starting platforms, not a compatibility list.
Capabilities can differ among SKUs in the same family, and firmware,
operating-system, or hypervisor configuration can hide otherwise supported
features. Newer does not automatically mean compatible, particularly for
AVX-512. Use `check_simd.py` for the specific machine.

Support is not reliably determined by CPU age or product family. Low-power,
embedded, virtualized, and vendor-specific models frequently differ from
nearby products. AVX and AVX-512 also require the operating system or
hypervisor to enable the corresponding extended register state.

Use the repository checker on the machine that will run the browser:

```shell
python3 check_simd.py --list-profiles
python3 check_simd.py --profile avx2_fma
```

To validate a configured build directly:

```shell
python3 check_simd.py --args-file /path/to/chromium/src/out/thorium/args.gn
```

The product profile selected by `setup.py --avx2` currently uses the stricter
`avx2_fma` profile. A CPU with AVX2 but without FMA or F16C is therefore not
compatible with that build.

## Availability

The build system supports more profiles than are necessarily published for
every release. Consult the assets and release notes for the specific version:

- [Main Thorium releases](https://github.com/Alex313031/thorium/releases)
- [Thorium for Windows on ARM](https://github.com/Alex313031/Thorium-WOA/releases)
- [Thorium for Raspberry Pi](https://github.com/Alex313031/Thorium-Raspi/releases)
- [ThoriumOS](https://github.com/Alex313031/ThoriumOS/releases)

ARM64 builds do not use x86 SSE/AVX profiles. Select the package matching the
operating system and architecture instead.

## Choosing a build

1. Match the operating system and architecture first.
2. Run `check_simd.py` for x86 or x64.
3. Choose the highest profile explicitly reported as supported and actually
   provided by that release.
4. If the browser exits immediately with an illegal-instruction failure, use a
   lower profile; changing the user agent or command line cannot add CPU
   instructions.

Higher profiles permit the compiler to use more instructions but do not
guarantee a fixed performance gain on every workload or processor.
