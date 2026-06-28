#!/bin/bash

# Copyright (c) 2026 Alex313031.

YEL='\033[1;33m' # Yellow
GRE='\033[1;32m' # Green
c0='\033[0m' # Reset Text
bold='\033[1m' # Bold Text

printf "\n" &&
printf "${GRE}Script to set chmod +x on all other Thorium scripts.\n" &&
tput sgr0 &&
printf "\n" &&

# Set executable permissions.
cd .. &&

sudo chmod -v +x build.sh &&

sudo chmod -v +x g &&

sudo chmod -v +x build_android.sh &&

sudo chmod -v +x create_dmg.sh &&

sudo chmod -v +x build_mac.sh &&

sudo chmod -v +x build_win.sh &&

sudo chmod -v +x check_simd.sh &&

sudo chmod -v +x clean.sh &&

sudo chmod -v +x setup.sh &&

sudo chmod -v +x trunk.sh &&

sudo chmod -v +x tot.sh &&

sudo chmod -v +x reset_depot_tools.sh &&

sudo chmod -v +x version.sh &&

sudo chmod -v +x upstream_version.sh &&

sudo chmod -v +x get_repo.sh &&

sudo chmod -v +x infra/arch-prerequisites.sh &&

sudo chmod -v +x infra/build_dmg_cr.sh &&

sudo chmod -v +x infra/build_polly.sh &&

sudo chmod -v +x infra/DEBUG/build_debug_linux.sh &&

sudo chmod -v +x infra/DEBUG/build_debug_shell_linux.sh &&

sudo chmod -v +x infra/DEBUG/build_debug_shell_win.sh &&

sudo chmod -v +x infra/DEBUG/build_debug_win.sh &&

sudo chmod -v +x infra/DEBUG/Thorium_Debug_Shell.sh &&

sudo chmod -v +x logos/NEW/mac/gen/app/build_icns.sh &&

sudo chmod -v +x infra/portable/THORIUM-PORTABLE &&

sudo chmod -v +x infra/portable/THORIUM-SHELL &&

sudo chmod -v +x infra/portable/thorium-portable.desktop &&

sudo chmod -v +x infra/portable/thorium-shell.desktop &&

sudo chmod -v +x infra/portable/make_portable_linux.sh &&

sudo chmod -v +x infra/portable/make_portable_win.sh &&

sudo chmod -v +x infra/APPIMAGE/pkg2appimage &&

sudo chmod -v +x infra/APPIMAGE/make_appimage.sh &&

sudo chmod -v +x infra/APPIMAGE/extract_appimage.sh &&

sudo chmod -v +x pak_src/build.sh &&

printf "\n" &&
printf "${GRE}${bold}Scripts are ready!\n" &&
printf "\n" &&
tput sgr0
