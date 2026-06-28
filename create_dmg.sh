#!/bin/bash

# Copyright (c) 2026 Alex313031 and midzer.

YEL='\033[1;33m' # Yellow
GRE='\033[1;32m' # Green

# chromium/src dir env variable.
if [ -z "${CR_DIR}" ]; then 
    CR_SRC_DIR="$HOME/chromium/src"
    export CR_SRC_DIR
else 
    CR_SRC_DIR="${CR_DIR}"
    export CR_SRC_DIR
fi

printf "\n" &&
printf "${YEL}Building .dmg of Thorium...\n" &&
printf "\n" &&

cd ${CR_SRC_DIR} &&

# Fix file attributes.
xattr -csr out/thorium/Thorium.app &&

# Sign binary.
codesign --force --deep --sign - out/thorium/Thorium.app &&

# Build dmg package.
chrome/installer/mac/pkg-dmg --sourcefile --source out/thorium/Thorium.app --target "out/thorium/Thorium_MacOS.dmg" --volname Thorium --symlink /Applications:/Applications --format UDBZ --verbosity 2 &&

cd $HOME/thorium &&
cat logos/apple_ascii_art.txt &&

printf "${GRE}.DMG Build Completed. ${YEL}Installer at \'//chromium/src/out/thorium/Thorium*_MacOS.dmg\'\n" &&
tput sgr0
