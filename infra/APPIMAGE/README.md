## Thorium AppImage Generation <img src="https://raw.githubusercontent.com/Alex313031/Thorium/main/logos/STAGING/Appimage_Logo.svg" width="36">

### Instructions
This directory contains files to generate an .AppImage of Thorium.

Build dependencies: `desktop-file-utils` and `imagemagick`.

You __must__ place the .deb file (generated from running `package.sh`) in this directory, and then run `./make_appimage.sh`.
You can also pass a package path directly, I.E. `./make_appimage.sh thorium-browser_150.0.7871.101_SSE3.deb`.

When it is done, you will have an appimage in *out* named after the .deb package, I.E. it should be something like `//thorium/infra/APPIMAGE/out/Thorium_Browser_150.0.7871.101_SSE3.AppImage`

You can use it standalone, after making it executable with `sudo chmod +x Thorium_Browser-*`, or (*recommended*) to integrate it with your system you can use [AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher).

 - Running `./extract_appimage.sh` will extract the appimage contents to *out/Thorium_squashfs-root*
 - The *files* subdir contains files needed for the 22px and 512px icons, and a thorium-shell wrapper that allows thorium_shell to run properly in an AppImage.

 - *See also:* [About AppImages](https://appimage.org/)

### About <img src="https://github.com/Alex313031/thorium/blob/main/logos/NEW/thorium_infra_256.png" width="32">
&ndash; This infra project uses [*pkg2appimage*](https://github.com/AppImage/pkg2appimage/blob/master/pkg2appimage) from here > https://github.com/AppImage/pkg2appimage \
&ndash; The [*Thorium.yml*](https://github.com/Alex313031/thorium/blob/main/infra/APPIMAGE/Thorium.yml) file was modeled after the official Chromium one from here > https://github.com/AppImage/pkg2appimage/blob/master/recipes/Chromium.yml
