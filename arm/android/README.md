# Android args.gn files

`debug_args.gn` targets ARM64. Use the other argument files as references when
creating an x86, x64, or ARM32 debug configuration; do not duplicate Chromium's
ARM ABI or microarchitecture settings in these files.

`android_full_debug = true` can be used for a more complete debug build.

`chromium_args.gn` is for an official, non-debug vanilla Chromium build.

API keys enable location-related features but do not provide desktop-style
Google Sync in Android Chromium because access is subject to additional Google
service restrictions.
