#!/bin/bash

# Copyright (c) 2026 Alex313031.

YEL='\033[1;33m' # Yellow
GRE='\033[1;32m' # Green

printf "\n" &&
printf "${YEL}Generating Thorium App .icns file for MacOS...\n" &&
printf "\n" &&

# Copy .pngs.
output_iconset_name="Thorium.iconset" &&

rm -r -f "${output_iconset_name}" &&
mkdir "${output_iconset_name}" &&

cp -v ./icon_16x16.png "${output_iconset_name}/" &&
cp -v ./icon_16x16@2x.png "${output_iconset_name}/" &&
cp -v ./icon_32x32.png "${output_iconset_name}/" &&
cp -v ./icon_32x32@2x.png "${output_iconset_name}/" &&
cp -v ./icon_64x64.png "${output_iconset_name}/" &&
cp -v ./icon_64x64@2x.png "${output_iconset_name}/" &&
cp -v ./icon_128x128.png "${output_iconset_name}/" &&
cp -v ./icon_128x128@2x.png "${output_iconset_name}/" &&
cp -v ./icon_256x256.png "${output_iconset_name}/" &&
cp -v ./icon_256x256@2x.png "${output_iconset_name}/" &&
cp -v ./icon_512x512.png "${output_iconset_name}/" &&
cp -v ./icon_512x512@2x.png "${output_iconset_name}/" &&

# Generate .icns file.
iconutil -c icns "${output_iconset_name}" &&

# Remove temp dir.
rm -r -v "${output_iconset_name}"

printf "\n" &&
printf "${GRE}Done!\n" &&
tput sgr0
