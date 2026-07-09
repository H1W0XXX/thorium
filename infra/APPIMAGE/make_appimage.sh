#!/bin/bash

# Copyright (c) 2026 Alex313031.

YEL='\033[1;33m' # Yellow
RED='\033[1;31m' # Red
GRE='\033[1;32m' # Green
c0=$'\033[0m' # Reset Text
bold=$'\033[1m' # Bold Text

# --help.
displayHelp () {
	printf "\n" &&
	printf "${bold}${GRE}Script to build Thorium .AppImage on Linux.${c0}\n" &&
	printf "${bold}${YEL}Usage: ./make_appimage.sh [thorium-browser_*.deb]${c0}\n" &&
	printf "${bold}${YEL}If no .deb is passed, place one in this directory before running.${c0}\n" &&
	printf "\n"
}
case $1 in
	--help) displayHelp; exit 0;;
esac

# Error handling.
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }

# Detect which .deb to package. Prefer an explicit path, otherwise keep the
# current directory workflow and choose by ISA priority.
if [ -n "$1" ]; then
	DEB_NAME="$1"
	if [ ! -f "$DEB_NAME" ]; then
		die "${RED}No such .deb file: ${DEB_NAME}${c0}"
	fi
else
	DEB_PATTERNS=(
		"*AVX512*.deb"
		"*AVX2*.deb"
		"*AVX*.deb"
		"*SSE4*.deb"
		"*SSE3*.deb"
		"*arm64*.deb"
		"*.deb"
	)

	DEB_NAME=""
	for pattern in "${DEB_PATTERNS[@]}"; do
		matches=( $pattern )
		if [ -f "${matches[0]}" ]; then
			DEB_NAME="${matches[0]}"
			break
		fi
	done
fi

if [ -z "$DEB_NAME" ]; then
	die "${RED}No .deb file found. Place a thorium-browser_*.deb in this directory or pass one as an argument.${c0}"
fi

DEB_BASENAME="$(basename "$DEB_NAME")"
APPIMAGE_BASENAME="${DEB_BASENAME%.deb}"
if [[ "$APPIMAGE_BASENAME" == thorium-browser_* ]]; then
	APPIMAGE_BASENAME="Thorium_Browser_${APPIMAGE_BASENAME#thorium-browser_}"
fi
APPIMAGE_NAME="${APPIMAGE_BASENAME}.AppImage"

printf "\n" &&
printf "${bold}${RED}NOTE: You must pass a Thorium .deb file or place one in this directory before running.${c0}\n" &&
printf "${bold}${YEL}Detected package: ${GRE}${DEB_NAME}${c0}\n" &&
printf "${bold}${YEL}Output AppImage will be: ${GRE}${APPIMAGE_NAME}${c0}\n" &&
printf "\n" &&
printf "${YEL}Extracting & Copying files from Thorium .deb package...\n" &&
printf "${c0}\n" &&

rm -r -f ./temp/ &&

sleep 2 &&

# Extract data.tar.xz.
mkdir -v ./temp &&
ar xv "$DEB_NAME" &&
tar xvf ./data.tar.xz &&
cp -r -v ./opt/chromium.org/thorium/* ./temp/ &&
cp -r -v ./files/product_logo_512.png ./temp/ &&
cp -r -v ./files/product_logo_22.png ./temp/ &&
cp -r -v ./files/thorium-shell ./temp/ &&
rm -r -v ./temp/cron &&
rm -r -v ./temp/thorium-browser &&

printf "\n" &&
printf "${YEL}Building .AppImage using Thorium.yml...\n" &&
printf "${c0}\n" &&

sleep 2 &&

# Build AppImage.
# chmod +x pkg2appimage &&
./pkg2appimage Thorium.yml &&

printf "\n" &&
printf "${YEL}Renaming AppImage to match .deb package name...\n" &&
printf "${c0}\n" &&

GENERATED_APPIMAGE="$(find ./out -maxdepth 1 -type f -name 'Thorium*.AppImage' -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)" &&
if [ -z "$GENERATED_APPIMAGE" ]; then
	die "${RED}No generated Thorium*.AppImage found in ./out.${c0}"
fi

if [ "$GENERATED_APPIMAGE" != "./out/${APPIMAGE_NAME}" ]; then
	mv -v "$GENERATED_APPIMAGE" "./out/${APPIMAGE_NAME}"
fi &&

printf "\n" &&
printf "${YEL}Cleaning up...\n" &&
printf "${c0}\n" &&

sleep 2 &&

# Cleanup.
rm -r -v -f ./opt &&
rm -r -v -f ./etc &&
rm -r -v -f ./usr &&
rm -r -v -f ./control.tar.xz &&
rm -r -v -f ./data.tar.xz &&
rm -r -v -f ./debian-binary &&
rm -r -v -f ./Thorium/ &&
rm -r -v -f ./temp/ &&

printf "\n" &&
printf "${GRE}Done! ${YEL}AppImage at //out/${APPIMAGE_NAME}\n" &&
printf "\n" &&
tput sgr0
