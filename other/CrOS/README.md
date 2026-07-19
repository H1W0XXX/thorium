# Thorium for ThoriumOS

This directory contains the Linux-ChromeOS configuration used to build Thorium
for [ThoriumOS](https://github.com/Alex313031/ThoriumOS), a ChromiumOS-derived
system. It is not a ChromeOS device-toolchain configuration.

The maintained [`cros_args.gn`](cros_args.gn) configuration currently selects:

```gn
target_os = "chromeos"
is_chromeos_device = false
target_cpu = "x64"
thorium_x86_profile = "sse4_1"
```

Prepare the Chromium tree and ThoriumOS version metadata from the Thorium
repository root:

```shell
python3 setup.py --cros
```

`setup.py` does not install the GN configuration. Use `cros_args.gn` as the
basis for Chromium's `out/thorium/args.gn`, then generate and build from
Chromium `src`:

```shell
gn gen out/thorium
python3 /path/to/thorium/build.py \
  --chromium-src /path/to/chromium/src --expect-os chromeos
```

The checkout must include the dependencies required by Chromium's
Linux-ChromeOS build. Destructive source synchronization and branch maintenance
are documented in the main
[building guide](../../docs/BUILDING.md#maintenance-and-cleanup).

<img src="https://github.com/Alex313031/ThoriumOS/blob/main/images/ChromiumBook_Black.png" alt="ThoriumOS" width="192">
