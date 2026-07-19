# Thorium FAQ

## Why does Android Google Sync sign-in fail?

Google API keys can enable some Google-backed services, but they do not grant a
third-party Android Chromium package access to Google Sync. Android browser
sign-in also depends on Google-controlled package and service authorization.
Thorium cannot bypass that authorization.

## Why does a streaming site reject playback or limit quality?

Widevine is Google's proprietary content-decryption module (CDM) for encrypted
media. Thorium can integrate a Widevine CDM on supported platforms, but merely
bundling the CDM does not make Thorium a Widevine VMP-verified application.

Widevine commonly distinguishes between software-backed L3 playback and more
strongly protected hardware-backed levels such as L1. Video providers may also
require Verified Media Path (VMP), platform-specific application signatures,
supported codecs, hardware decoding, or a particular device security level.
The signature shipped with a CDM authenticates that CDM binary; it is not the
same as a VMP signature covering the browser executable.

This distinction is particularly visible with independent Chromium builds:

- Linux services may permit software-backed playback while limiting resolution
  or available content.
- Windows and macOS services may require application verification that Thorium
  does not possess, even when the bundled CDM itself loads successfully.
- Hardware-backed high-resolution playback depends on the device, operating
  system, media pipeline, and the provider's policy; a capable GPU alone does
  not guarantee it.

Sites choose their own DRM level and application requirements, so behavior can
differ by site and platform. Changing the user agent to report another browser
or operating system does not provide the missing CDM security level or
application verification.

Report a reproducible Thorium regression, but do not assume that every policy
restriction imposed by a streaming service can be fixed in browser code.

## Why does Thorium's version sometimes lag behind Chromium?

Thorium tracks Chromium's Stable branch, but its releases are produced
independently and do not necessarily appear at the same time as Google Chrome
or Chromium releases. Thorium is not intentionally kept one major version
behind, nor does it promise to publish a build for every Chromium point
release. A point release may be skipped when its changes will be included in a
subsequent Thorium release.

Rebasing, compiling the supported platforms and variants, testing the results,
and correcting regressions can take several days. A Thorium release therefore
may not appear on the same schedule as the corresponding Google Chrome or
Chromium release, even though it is based on the Stable branch. Check the full
version on `thorium://version` (or `chrome://version`) and compare it with the
current [Thorium releases](https://github.com/Alex313031/thorium/releases).

## Is Thorium ungoogled-chromium?

No. Thorium incorporates selected privacy and usability changes, including
some work derived from ungoogled-chromium and other Chromium forks, but it does
not attempt to remove every Google service or domain. The exact patch inventory
and known origins are recorded in [`PATCHES.md`](PATCHES.md).

## Which SSE or AVX build should I download?

Use [`check_simd.py`](../check_simd.py) and follow the [release variant
guide](ABOUT_RELEASES.md). CPU family names and manufacturing dates are not
reliable compatibility checks. ARM64 builds do not use x86 SIMD variants.

## Does Thorium support Manifest V2 extensions?

Thorium carries patches that retain Manifest V2 support and includes
extension-related controls beyond stock Chromium. Extension installation and
updates can still be affected by Chrome Web Store policy, browser flags,
platform support, and changes in Chromium's extension implementation.

## How do I build Thorium?

Start with the [documentation index](README.md) and select the platform build
guide. The repository workflow requires Python 3.11 or newer and uses
`get_repo.py`, `version.py`, `setup.py`, GN, and `build.py`.

## How should I report a bug?

Search the [issue tracker](https://github.com/Alex313031/thorium/issues) for an
existing report before opening a new issue. When creating an issue, follow the
applicable issue template and provide all information it requests.
