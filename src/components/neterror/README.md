# Thorium Neterror Overlay&nbsp;&nbsp;<img src="https://github.com/Alex313031/thorium/blob/main/logos/NEW/components/200/error_network_generic.png" width="48" alt="Network error icon">

This overlay carries Thorium-specific binary resources for Chromium's network
error page and offline dino game. Preview Chromium's registered network-error
pages through `thorium://network-errors` or the compatible
`chrome://network-errors` URL.

## Integration

The root-level `setup.py` copies this directory over Chromium's
`components/neterror` tree before applying the ordered patch series. The
[`thorium-dino-game.patch`](../../../other/thorium-dino-game.patch) patch then
adds the source-level Thorium behavior to Chromium's current implementation.

Keep Chromium-owned source files such as `resources/neterror.html` and
`resources/dino_game/offline.ts` in the patch rather than copying them into
this overlay. Those files change upstream and must be rebased against the
current Chromium source.

The checked-in binary resources remain in the overlay because they cannot be
represented usefully as textual patches:

- `resources/images/default_100_percent/offline/*.png`
- `resources/images/default_200_percent/offline/*.png`
- `resources/sounds/perpetuum_factory_2.mp3`

The six PNG files replace Chromium's currently referenced 1x and 2x offline
page artwork at the same paths. They are Thorium-specific files and differ
from the corresponding Chromium resources. The MP3 is referenced by the
additional `<audio>` element and playback logic introduced by
`thorium-dino-game.patch`.

## Provenance

Thorium's Git history records the PNG artwork entering the repository in 2022
and `perpetuum_factory_2.mp3` in 2024.

## Upstream references

- [Chromium neterror component](https://chromium.googlesource.com/chromium/src/+/main/components/neterror/)
- [Shared Chromium security-interstitial resources](https://chromium.googlesource.com/chromium/src/+/main/components/security_interstitials/core/common/resources/)
