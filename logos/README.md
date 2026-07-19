# Thorium logos

<img src="https://github.com/Alex313031/thorium/blob/main/logos/STAGING/thorium_bubbles.svg" alt="Thorium bubbles">

This directory contains Thorium brand artwork, platform exports, documentation
images, historical designs, and terminal ASCII art. Files under `logos/` are
design sources and reusable exports; Chromium build inputs are maintained in
the appropriate overlay paths under `src/` and synchronized by Thorium setup
or generation tools.

## Directory layout

- [`NEW`](NEW/) contains the current primary brand artwork and platform export
  resources. Not every file in this directory is copied directly into a build.
- [`NEW/android`](NEW/android/) contains Android application and first-run
  artwork.
- [`NEW/chromeos`](NEW/chromeos/) contains ChromeOS and file-manager exports.
- [`NEW/linux`](NEW/linux/) contains Linux XPM application icons.
- [`NEW/mac`](NEW/mac/) contains macOS exports and document artwork. The
  [macOS application icon generator](NEW/mac/gen/README.md) owns the current
  layered `AppIcon.icon`, `Assets.car`, and compatibility `app.icns` workflow.
- [`NEW/win`](NEW/win/) contains Windows application, installer, and document
  resources.
- [`NEW/webui`](NEW/webui/) contains WebUI artwork.
- [`NEW/thorium_shell`](NEW/thorium_shell/) and
  [`NEW/thorium_debug_shell`](NEW/thorium_debug_shell/) contain product-specific
  shell artwork.
- [`STAGING`](STAGING/) is a mixed collection of documentation, presentation,
  experimental, and staging assets. Several repository documents reference
  files there, so the directory is not disposable scratch space.
- [`OLD`](OLD/) preserves historical Thorium and Technetium designs that are no
  longer current build sources.
- [`PRE_DPI_FIX_BACKUP`](PRE_DPI_FIX_BACKUP/) preserves exports from before the
  DPI asset correction and is not a current build source.
- The root `*_ascii_art.txt` files provide terminal artwork used by repository
  scripts.

The project briefly used the name
[Technetium](https://github.com/Alex313031/Technetium); surviving experiments
are retained only as historical assets under `OLD/`.

## Build integration

Updating a design under `logos/NEW` does not by itself update Chromium. Review
the corresponding files under:

```text
src/chrome/app/theme/chromium/
```

Platform setup, patch, or generation workflows determine which files are copied
or generated. In particular, do not manually replace macOS `Assets.car` or
`app.icns`; follow [`NEW/mac/gen/README.md`](NEW/mac/gen/README.md) so both are
generated from the same checked-in sources.

## Licensing

- The Thorium circular atom/roundel and Thorium wordmark artwork are licensed
  under GPL-3.0-only. The exact covered source files, platform exports, and
  corresponding overlay derivatives are defined in
  [`THORIUM_LOGO_LICENSE.md`](THORIUM_LOGO_LICENSE.md). The complete license
  text is in [`GPL-3.0.txt`](GPL-3.0.txt).
- Chromium-derived branding remains under Chromium's BSD-style
  [`CHROMIUM_LICENSE`](../infra/CHROMIUM_LICENSE).
- Assets explicitly identified as Apache-derived are covered by
  [`APACHE_LICENSE.txt`](APACHE_LICENSE.txt). The presence of that file does
  not make every asset in this directory Apache-licensed.
- Third-party logos and photographs retain their respective owners' rights and
  are not relicensed merely by being stored in this directory.
- Thorium source code outside the explicitly covered logo artwork remains under
  the repository's [BSD 3-Clause license](../LICENSE.md), unless a file states
  otherwise.

<img src="https://github.com/Alex313031/thorium/blob/main/logos/STAGING/error_dog.png" alt="Thorium error dog" width="256">
