#!/bin/bash

# Copyright (c) 2026 Alex313031.

YEL='\033[1;33m' # Yellow
GRE='\033[1;32m' # Green
c0=$'\033[0m' # Reset Text
bold=$'\033[1m' # Bold Text
underline=$'\033[4m' # Underline Text

# --help.
displayHelp () {
	printf "\n" &&
	printf "${bold}${YEL}Script to build Thorium DEBUG for Windows on Linux.${c0}\n" &&
	printf "${underline}Usage: ${c0}build_debug_win.sh # (where # is number of jobs)\n" &&
	printf "\n"
}
case $1 in
	--help) displayHelp; exit 0;;
esac

printf "\n" &&
printf "${YEL}Building Thorium DEBUG for Windows...\n" &&
printf "\n" &&

# Build Thorium and Thorium UI Debug Shell.
export NINJA_SUMMARIZE_BUILD=1 &&

# chromium/src dir env variable.
if [ -z "${CR_DIR}" ]; then
    CR_SRC_DIR="$HOME/chromium/src"
    export CR_SRC_DIR
else
    CR_SRC_DIR="${CR_DIR}"
    export CR_SRC_DIR
fi

autoninja -C ${CR_SRC_DIR}/out/thorium chrome chromedriver thorium_shell setup mini_installer thorium_ui_debug_shell clear_key_cdm -j$@ &&

mkdir -v -p ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell &&
mkdir -v -p ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/icons &&

cp -r -f -v ./icons/icon_16.png ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/icons &&
cp -r -f -v ./icons/icon_24.png ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/icons &&
cp -r -f -v ./icons/icon_32.png ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/icons &&
cp -r -f -v ./icons/icon_48.png ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/icons &&
cp -r -f -v ./icons/icon_64.png ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/icons &&
cp -r -f -v ./icons/icon_128.png ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/icons &&
cp -r -f -v ./icons/icon_256.png ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/icons &&
cp -r -f -v ./icons/thorium_debug_shell.ico ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell &&
cp -r -f -v DEBUG_SHELL_README.md ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/README.md &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/locales ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/test_fonts ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/resources ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/ui ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/blink_test_plugin.dll ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/icudtl.dat ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/content_resources.pak ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/libEGL.dll ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/libGLESv2.dll ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/vk_swiftshader.dll ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/vulkan-1.dll ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/vk_swiftshader_icd.json ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/v8_context_snapshot.bin ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/v8_context_snapshot_generator ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/ui_resources_100_percent.pak ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/ui_test.pak ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/ui_test_200_percent.pak ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/views_examples_resources.pak ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&
cp -r -f -v ${CR_SRC_DIR}/out/thorium/thorium_ui_debug_shell.exe ${CR_SRC_DIR}/out/thorium/Thorium_UI_Debug_Shell/ &&

printf "\n" &&
printf "${GRE}Debug Windows Build Completed.\n" &&
tput sgr0
