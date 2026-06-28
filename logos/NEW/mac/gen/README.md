## ICNS generation directory. <img src="https://github.com/Alex313031/thorium/blob/main/logos/NEW/mac/icon_2048px.png" width="48">

This directory contains files/scripts for generating a .icns (IconSet) file for MacOS from predefined icon .PNGs from 16px to 1024px.

 - In the app subdir, there are the icon files and a script named build_icns.sh, which must be run in that folder.
It will generate `Thorium.icns`, which should be placed in the parent of this directory, I.E. //thorium/logos/NEW/mac/

It will then be renamed to app.icns and copied to //thorium/chrome/app/theme/chromium/mac/ for proper Thorium branding on MacOS.

<img src="https://github.com/Alex313031/thorium/blob/main/logos/NEW/mac/apple.png" width="200">
